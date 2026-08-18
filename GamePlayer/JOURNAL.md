# UIKit Vertical Feed Journal

## Goal
Build a robust UIKit-based, full-screen vertical feed for interactive web games. Each page should render one supplied URL inside a `WKWebView`, while preserving a dedicated 123pt footer that remains available for feed pagination gestures.

## Implemented Solution

### 1. SwiftUI to UIKit bridge
The app still launches from SwiftUI, but `ContentView` now hosts a UIKit controller using `UIViewControllerRepresentable`. This keeps the project entry simple while allowing the feed implementation to live entirely in UIKit.

### 2. Full-screen vertical paging feed
A `VerticalFeedViewController` now owns a vertically paging `UICollectionView` configured for one full-screen item per page. The controller:
- sizes every item to match the collection view bounds
- enables vertical paging
- registers a reusable `FeedWebViewCell`
- passes the shared collection view pan gesture to each cell footer

### 3. Reusable web feed cell
`FeedWebViewCell` owns:
- one `WKWebView`
- a loading indicator
- a lightweight error state
- a bottom footer overlay with a drag affordance and instructional copy

The web view is configured for interactive content:
- JavaScript enabled
- inline media playback allowed
- media playback not blocked by additional user action requirements

### 4. Dedicated 123pt drag footer
The footer is intentionally separated from the active web content area. This is the primary gesture-conflict solution:
- the game area remains interactive for taps and drags
- the footer stays reserved for collection view paging
- the collection view pan recognizer is attached to the footer so dragging there paginates the feed

### 5. URL data source
The 25 provided URLs are stored in `FeedURLs.all` and injected directly into the feed controller.

## Why this approach
Interactive HTML5 games inside `WKWebView` aggressively consume touch input. If the whole screen were responsible for feed paging, game gestures and feed gestures would compete constantly. Reserving a footer-only gesture zone is the most reliable UIKit solution for TikTok-style page transitions over fully interactive web content.

## Caveats

### Gesture recognizer ownership
The current implementation reuses the collection view's pan recognizer by attaching it to the footer view of visible cells. This is a pragmatic approach for the first version, but gesture recognizers in UIKit are sensitive to view ownership and reuse patterns. If runtime behavior shows instability, the next step should be:
- keep the collection view pan recognizer on the collection view
- add a dedicated footer pan recognizer
- translate footer drag progress into collection view content offset or target-page scrolling manually

That alternative is more explicit and usually easier to reason about under heavy reuse.

### WKWebView memory cost
`WKWebView` is expensive. The implementation relies on collection view reuse and does not attempt to keep all 25 web views alive at once. This is intentional. If smoother transitions are needed later, preloading only adjacent items should be considered rather than broad caching.

### Game state persistence
A reused cell may reset its web content. This is acceptable for a first pass, but it means users may lose in-progress game state after moving far enough away for the cell to be reused.

### External navigation policy
If a page tries to open another host or a new window, the current logic sends that navigation to the system browser instead of allowing the feed web view to leave the original content context. This keeps the feed stable, but it may need tuning depending on how the target game pages behave.

### Loading and error handling
The feed currently uses a basic spinner and error message. This is enough to make failures visible, but not enough for advanced retry or analytics flows.

### Safe area interpretation
The footer height is currently 123pt anchored to the bottom edge of the cell. On devices with a home indicator, that means part of the visual area overlaps the bottom safe area region. If the design requires 123pt of fully usable content above the safe area, the footer constraints should be adjusted in a later pass.

## Recommended follow-up improvements
1. Replace footer gesture reuse with a dedicated footer pan driver if interaction proves unreliable.
2. Add visibility callbacks for pause/resume hooks if the game pages expose them.
3. Add adjacent-page prewarming for faster transitions.
4. Add retry UI and lightweight telemetry for failed page loads.
5. Decide whether the app should be portrait-only for a more predictable feed layout.