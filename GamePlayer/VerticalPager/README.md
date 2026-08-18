# MA Feed Engine

This folder contains the native vertical-feed engine used by MA Game Feed. It is intentionally UIKit-first: `UICollectionView` gives predictable reuse and gesture control while each page hosts a web game.

## Core API

```swift
let pager = MAFeedPagerController(
    items: games,
    overlayConfiguration: .default,
    onActionBarInteraction: { game, action in
        // Forward native actions to the host app.
    },
    onPullToRefresh: {
        // Refresh the feed source.
    }
)
```

`MAPlayableGame` is the feed model. The pager configures a reused `MAStagePlayerCell` for each visible item and promotes only the current item to the primary playback state.

## Important components

- `MAFeedPagerController` — gesture-driven vertical paging, page-change callbacks, and pull-to-refresh.
- `MAStagePlayerCell` — lazy web-game loading, native metadata/actions, and reuse reset.
- `MAWebViewFactory` — ephemeral, JavaScript-capable web views for game compatibility.
- `MAWebNavigationPolicy` — rejects any navigation that is not HTTPS, including redirects and responses.
- `MAFeedGeometry` and `MAOverlaySettings` — layout and overlay behavior.

## Performance contract

Do not eagerly create a player for the whole feed. The cell's `applyPlaybackState` method loads the game only after it becomes primary, while `prepareForReuse` stops work and clears stale web content. This retains responsive native paging even when the catalog is large.

## Integration boundaries

The folder uses only Apple frameworks. Hosts own game metadata, action handling, analytics, and catalog refresh. Keep the security policy in place unless the host can replace the HTTPS rule with a stricter curated-domain allowlist.
