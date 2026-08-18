#!/usr/bin/env python3
"""Export the feed-ready fields from a RezonA enriched catalog.

Usage:
    python3 tools/export_rezona_catalog.py \
      /path/to/games.enriched.json GamePlayer/GameCatalog.json
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def non_empty_string(value: Any) -> str | None:
    if not isinstance(value, str):
        return None
    value = value.strip()
    return value or None


def non_negative_int(value: Any) -> int | None:
    return value if isinstance(value, int) and value >= 0 else None


def export_catalog(source_path: Path, destination_path: Path) -> int:
    with source_path.open(encoding="utf-8") as source_file:
        source = json.load(source_file)

    records: list[dict[str, Any]] = []
    for entry in source.get("games", []):
        game = entry.get("game", {})
        playable_url = non_empty_string(game.get("url"))
        if playable_url is None:
            continue

        creator = game.get("creator") or {}
        stats = game.get("stats") or {}
        records.append(
            {
                "url": playable_url,
                "title": non_empty_string(game.get("name")),
                "description": non_empty_string(game.get("description")),
                "username": non_empty_string(creator.get("name")),
                "avatarURL": non_empty_string(creator.get("avatar")),
                "remixCount": non_negative_int(game.get("remixed_games")),
                "likeCount": non_negative_int(stats.get("liked_count")),
                "shareCount": non_negative_int(stats.get("shared_count")),
                "chatCount": non_negative_int(stats.get("comment_count")),
            }
        )

    destination_path.parent.mkdir(parents=True, exist_ok=True)
    with destination_path.open("w", encoding="utf-8") as destination_file:
        json.dump(records, destination_file, ensure_ascii=False, separators=(",", ":"))
        destination_file.write("\n")

    return len(records)


def main() -> None:
    parser = argparse.ArgumentParser(description="Export a RezonA catalog for GamePlayer.")
    parser.add_argument("source", type=Path, help="Path to games.enriched.json")
    parser.add_argument("destination", type=Path, help="Output GameCatalog.json path")
    args = parser.parse_args()

    count = export_catalog(args.source, args.destination)
    print(f"Exported {count} playable games to {args.destination}")


if __name__ == "__main__":
    main()
