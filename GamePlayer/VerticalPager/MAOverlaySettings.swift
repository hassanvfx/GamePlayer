import CoreGraphics
import Foundation

struct MAOverlaySettings: Hashable {
    struct MAHiddenHotArea: Hashable {
        enum MASide: Hashable {
            case leading
            case trailing
        }

        let side: MASide
        let width: CGFloat

        init(side: MASide, width: CGFloat = 88) {
            self.side = side
            self.width = width
        }
    }

    let autoHideDelay: TimeInterval?
    let hiddenHotArea: MAHiddenHotArea?
    let autoShowActionBar: Bool
    let actionBarIdleDelay: TimeInterval

    init(
        autoHideDelay: TimeInterval? = nil,
        hiddenHotArea: MAHiddenHotArea? = nil,
        autoShowActionBar: Bool = false,
        actionBarIdleDelay: TimeInterval = 1
    ) {
        self.autoHideDelay = autoHideDelay
        self.hiddenHotArea = hiddenHotArea
        self.autoShowActionBar = autoShowActionBar
        self.actionBarIdleDelay = actionBarIdleDelay
    }

    static let `default` = MAOverlaySettings()
}
