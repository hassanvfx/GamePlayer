import UIKit

enum MAWalkthroughStepID: Hashable {
    case swipeUp
    case save
    case remix
    case finalize
}

struct MAWalkthroughStep: Hashable {
    enum MAHighlightTarget: Hashable {
        case none
        case like
        case chat
    }

    let id: MAWalkthroughStepID
    let pageIndex: Int
    let title: String
    let message: String
    let symbolName: String
    let highlightTarget: MAHighlightTarget
    let showsPrimaryButton: Bool
    let primaryButtonTitle: String?
    let isVisible: Bool

    static let `default`: [MAWalkthroughStep] = [
        MAWalkthroughStep(
            id: .swipeUp,
            pageIndex: 0,
            title: "Swipe up",
            message: "New game",
            symbolName: "arrow.up",
            highlightTarget: .none,
            showsPrimaryButton: false,
            primaryButtonTitle: nil,
            isVisible: true
        ),
        MAWalkthroughStep(
            id: .save,
            pageIndex: 1,
            title: "Tap the heart",
            message: "Keep this game",
            symbolName: "heart.fill",
            highlightTarget: .like,
            showsPrimaryButton: false,
            primaryButtonTitle: nil,
            isVisible: true
        ),
        MAWalkthroughStep(
            id: .remix,
            pageIndex: 2,
            title: "Tap Remix",
            message: "Make it yours",
            symbolName: "shuffle",
            highlightTarget: .none,
            showsPrimaryButton: false,
            primaryButtonTitle: nil,
            isVisible: true
        ),
        MAWalkthroughStep(
            id: .finalize,
            pageIndex: 3,
            title: "",
            message: "",
            symbolName: "",
            highlightTarget: .none,
            showsPrimaryButton: false,
            primaryButtonTitle: nil,
            isVisible: false
        )
    ]
}
