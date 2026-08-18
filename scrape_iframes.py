#!/usr/bin/env python3

import json
import re
import sys
from typing import Dict, List, Optional, Set
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup

# ------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------

TIMEOUT = 20
USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/123.0.0.0 Safari/537.36"
)

HEADERS = {
    "User-Agent": USER_AGENT,
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
}

OUTPUT_FILE = "urls_games.txt"

# Keep this empty if you prefer using urls.txt:
# python3 scrape_iframes.py urls.txt
URLS = []

GAMES_URL_REGEX = re.compile(
    r'https?://games\.jabali\.ai[^\s"\'<>]+',
    re.IGNORECASE,
)


# ------------------------------------------------------------
# HELPERS
# ------------------------------------------------------------

def normalize_candidate_url(candidate: str, base_url: str) -> str:
    candidate = candidate.strip()
    if not candidate:
        return ""

    if candidate.startswith("//"):
        return "https:" + candidate

    if candidate.startswith("/"):
        return urljoin(base_url, candidate)

    if candidate.startswith("http://") or candidate.startswith("https://"):
        return candidate

    return urljoin(base_url, candidate)


def normalize_playable_url(raw_url: str) -> str:
    parsed = urlparse(raw_url.strip())
    path = parsed.path.rstrip("/")

    if path.startswith("/game/"):
        path = "/play/" + path[len("/game/"):]
    elif not path.startswith("/play/"):
        return raw_url.strip()

    normalized = f"{parsed.scheme}://{parsed.netloc}{path}/"
    if parsed.query:
        normalized += f"?{parsed.query}"
    if parsed.fragment:
        normalized += f"#{parsed.fragment}"
    return normalized


def normalize_pdp_url(raw_url: str) -> str:
    parsed = urlparse(raw_url.strip())
    path = parsed.path.rstrip("/")

    if path.startswith("/play/"):
        path = "/game/" + path[len("/play/"):]
    elif not path.startswith("/game/"):
        return raw_url.strip()

    normalized = f"{parsed.scheme}://{parsed.netloc}{path}/"
    if parsed.query:
        normalized += f"?{parsed.query}"
    if parsed.fragment:
        normalized += f"#{parsed.fragment}"
    return normalized


def is_games_subdomain(url: str) -> bool:
    try:
        parsed = urlparse(url)
        return parsed.netloc.lower() == "games.jabali.ai"
    except Exception:
        return False


def fetch_html(url: str) -> str:
    resp = requests.get(url, headers=HEADERS, timeout=TIMEOUT)
    resp.raise_for_status()
    return resp.text


def parse_next_data(html: str) -> Dict:
    soup = BeautifulSoup(html, "html.parser")
    next_data = soup.find("script", id="__NEXT_DATA__")
    if not next_data or not next_data.string:
        return {}

    try:
        return json.loads(next_data.string)
    except Exception:
        return {}


def extract_pdp_metadata(html: str, pdp_url: str) -> Dict[str, Optional[str]]:
    soup = BeautifulSoup(html, "html.parser")
    next_data = parse_next_data(html)

    page_props = next_data.get("props", {}).get("pageProps", {})
    game = page_props.get("game", {})

    title_tag = soup.find("title")
    description_tag = soup.find("meta", attrs={"name": "description"})
    canonical_tag = soup.find("link", attrs={"rel": "canonical"})

    title = title_tag.get_text(strip=True) if title_tag else None
    description = description_tag.get("content", "").strip() or None if description_tag else None
    canonical_url = canonical_tag.get("href", "").strip() or None if canonical_tag else None

    username = None
    if game.get("user_id"):
        username = f"@{game['user_id']}"

    return {
        "source_url": pdp_url,
        "title": title or game.get("title"),
        "description": description or game.get("description"),
        "canonical_url": canonical_url,
        "game_id": game.get("id"),
        "user_id": game.get("user_id"),
        "genre": game.get("genre"),
        "poster": game.get("poster"),
        "username": username,
    }


def extract_games_urls_from_next_data(html: str) -> List[str]:
    next_data = parse_next_data(html)
    found: Set[str] = set()

    page_props = next_data.get("props", {}).get("pageProps", {})
    game = page_props.get("game", {})
    play_url = page_props.get("playUrl", "")
    user_id = game.get("user_id", "")
    game_id = game.get("id", "")

    if play_url and user_id and game_id:
        found.add(f"{play_url.rstrip('/')}/{user_id}/{game_id}/?demo=true")

    return sorted(found)


def extract_games_urls(html: str, page_url: str) -> List[str]:
    soup = BeautifulSoup(html, "html.parser")
    found: Set[str] = set()

    for iframe in soup.find_all("iframe"):
        for attr in ("src", "data-src", "data-iframe-src"):
            raw = iframe.get(attr)
            if not raw:
                continue
            full = normalize_candidate_url(raw, page_url)
            if is_games_subdomain(full):
                found.add(full)

    for match in GAMES_URL_REGEX.findall(html):
        full = normalize_candidate_url(match, page_url)
        if is_games_subdomain(full):
            found.add(full)

    for match in extract_games_urls_from_next_data(html):
        if is_games_subdomain(match):
            found.add(match)

    return sorted(found)


def swift_string(value: Optional[str]) -> str:
    if value is None:
        return "nil"
    escaped = (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
    )
    return f'"{escaped}"'


def build_swift_item(record: Dict[str, Optional[str]]) -> str:
    return (
        "TopGameSeed("
        f"webURL: URL(string: {swift_string(record['games_url'])})!, "
        f"title: {swift_string(record['title'])}, "
        f"description: {swift_string(record['description'])}, "
        f"username: {swift_string(record['username'])}, "
        "remixCount: 0, "
        "likeCount: 0, "
        "shareCount: 0, "
        "chatCount: 0"
        ")"
    )


def write_output_file(records: List[Dict[str, Optional[str]]], path: str = OUTPUT_FILE) -> None:
    items = ",\n    ".join(build_swift_item(record) for record in records)
    content = (
        "let topGames: [TopGameSeed] = [\n"
        f"    {items}\n"
        "]\n"
    )
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


def scrape_pages(urls: List[str]) -> List[Dict[str, Optional[str]]]:
    records: List[Dict[str, Optional[str]]] = []
    seen_games_urls: Set[str] = set()

    for idx, source_url in enumerate(urls, start=1):
        pdp_url = normalize_pdp_url(source_url)
        playable_url = normalize_playable_url(source_url)

        print(
            f"[{idx}/{len(urls)}] Fetching PDP URL: {pdp_url}",
            file=sys.stderr,
        )

        try:
            pdp_html = fetch_html(pdp_url)
            metadata = extract_pdp_metadata(pdp_html, pdp_url)
        except Exception as exc:
            print(f"  PDP ERROR: {exc}", file=sys.stderr)
            continue

        print(
            f"[{idx}/{len(urls)}] Fetching playable URL: {playable_url}",
            file=sys.stderr,
        )

        try:
            play_html = fetch_html(playable_url)
            games_urls = extract_games_urls(play_html, playable_url)
        except Exception as exc:
            print(f"  PLAY ERROR: {exc}", file=sys.stderr)
            games_urls = []

        for games_url in games_urls:
            if games_url in seen_games_urls:
                continue
            seen_games_urls.add(games_url)

            record = dict(metadata)
            record["play_page_url"] = playable_url
            record["games_url"] = games_url
            records.append(record)

    return records


def print_results(records: List[Dict[str, Optional[str]]]) -> None:
    for record in records:
        print(f"\nTITLE: {record['title']}")
        print(f"DESCRIPTION: {record['description']}")
        print(f"SOURCE: {record['source_url']}")
        print(f"PLAY:   {record['play_page_url']}")
        print(f"GAME:   {record['games_url']}")

    write_output_file(records, OUTPUT_FILE)

    print(f"\nTotal items written: {len(records)}")
    print(f"Written to: {OUTPUT_FILE}")


# ------------------------------------------------------------
# OPTIONAL: LOAD URLS FROM FILE
# ------------------------------------------------------------

def load_urls_from_file(path: str) -> List[str]:
    urls: List[str] = []
    with open(path, "r", encoding="utf-8") as f:
        for raw_line in f:
            line = raw_line.strip()
            if not line:
                continue

            line = re.sub(r"^\d+\.\s*", "", line)

            match = re.search(r"https?://\S+", line)
            if match:
                urls.append(match.group(0).strip())

    seen = set()
    deduped = []
    for url in urls:
        if url not in seen:
            seen.add(url)
            deduped.append(url)
    return deduped


def main():
    urls = URLS

    if len(sys.argv) > 1:
        urls = load_urls_from_file(sys.argv[1])

    if not urls:
        print("No URLs found.")
        sys.exit(1)

    records = scrape_pages(urls)
    print_results(records)


if __name__ == "__main__":
    main()