# MA Game Feed

An iOS, TikTok-style feed for playable web games. `MA Game Feed` combines a native, full-screen vertical pager with isolated `WKWebView` game sessions so a high-volume catalog can feel immediate without building every game page as native UI.

## Why this architecture

Game feeds have two competing interactions: the game needs direct touch input, while the feed needs decisive vertical paging. This project keeps those responsibilities separate:

- `MAFeedPagerController` owns the native `UICollectionView`, drag thresholds, page settling, and pull-to-refresh.
- `MAStagePlayerCell` owns one game session, its loading/error state, and lightweight native metadata/actions.
- The active page alone is interactive; reused cells clear their web state before they render a new game.
- `MAFeedScene` is a small SwiftUI-to-UIKit bridge, so the app can use UIKit performance characteristics without giving up the SwiftUI app lifecycle.

The result is a practical pattern for content-heavy, full-screen experiences: native scrolling and chrome stay fast, while the game remains an independently loaded web surface.

## Performance details

The feed is designed to avoid the common failure mode of creating a web view for every item in a large catalog.

- **UICollectionView reuse** bounds the number of live player cells to the visible viewport rather than the catalog size.
- **Lazy loading** starts a game only when its page becomes the primary page. Off-screen pages do not begin network work just because they exist in the feed.
- **Fast page snapping** uses a custom pan gesture with distance and velocity thresholds instead of relying on a web view's scroll state.
- **Ephemeral game sessions** prevent cookies and web storage from accumulating across a long session.
- **Avatar caching** avoids repeat image decoding while validating HTTPS, image MIME type, and a 2 MB response limit.
- **Focused source modules** keep the player cell below 500 lines; navigation, web-view construction, controls, and loading responsibilities are isolated.

For production feeds with especially heavy games, profile on target hardware before adding preloading. Adjacent-page preloads can improve perceived latency but increase `WKWebView` memory pressure.

## Security model

Games are remote, untrusted web content. JavaScript and inline/autoplay media are enabled because many games require them, but the app deliberately limits the native attack surface:

- only `https` navigation is allowed, including redirects and navigation responses;
- `http`, `file`, `data`, `javascript`, custom schemes, and invalid URLs are cancelled;
- every player uses a non-persistent `WKWebsiteDataStore`;
- the app has no JavaScript bridge or native script injection;
- catalog and avatar URLs are validated before use.

The policy deliberately permits any HTTPS host to support game CDNs and cross-domain assets. If the catalog becomes curated, replace that policy with an explicit host allowlist.

## Project map

| Area | Main types | Responsibility |
| --- | --- | --- |
| App bridge | `MAArcadeApp`, `MAFeedScene` | SwiftUI lifecycle and UIKit host |
| Feed engine | `MAFeedPagerController`, `MAPlayableGame` | Paging, feed state, callbacks |
| Game player | `MAStagePlayerCell`, `MAWebViewFactory` | Reused web-game session and native overlay |
| Safety | `MAWebNavigationPolicy`, `MAAvatarImageLoader` | HTTPS-only navigation and safe avatar loading |
| Catalog | `MAArcadeCatalog`, `GameCatalog.json` | Bundled playable-game metadata |
| Onboarding | `MAWalkthroughCurtain`, `MAWalkthroughCard` | Native gesture and action guidance |

## Run locally

1. Open `GamePlayer.xcodeproj` in Xcode.
2. Choose an iOS simulator or device and run the `GamePlayer` scheme.
3. Swipe vertically to move between games; pull down on the first item to invoke the feed refresh callback.

The bundled `GameCatalog.json` is generated from an enriched source catalog. Refresh it with:

```bash
python3 tools/export_rezona_catalog.py /path/to/games.enriched.json GamePlayer/GameCatalog.json
```

Only redistribute game catalog data when you have permission from the platform and creators.

## Quality checks

Install the versioned tools used by CI, then run:

```bash
scripts/format-swift.sh
scripts/lint-swift.sh
scripts/test-ios.sh
```

The repository uses SwiftFormat for deterministic rewriting, SwiftLint for strict static checks, and GitHub Actions for pull-request validation. The test script defaults to an `iPhone 16` simulator; override it with `IOS_DESTINATION` when needed.

## Extension points

- Wire `onActionBarInteraction` to real save, share, remix, and chat services.
- Supply an `onPullToRefresh` callback that refreshes the catalog or a remote feed page.
- Add an HTTPS host allowlist when the game provider set is known.
- Measure memory and load time before introducing adjacent-page prewarming.

## Requirements

- Xcode with an iOS SDK
- iOS 26 deployment target (as configured by the project)
- Apple frameworks only at runtime: UIKit, SwiftUI, Foundation, and WebKit
