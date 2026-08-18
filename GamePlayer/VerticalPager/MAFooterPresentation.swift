import Foundation

enum MAFooterRevealStage: Hashable {
    case hidden
    case save
    case chat
    case full
}

enum MAFooterPresentation: Hashable {
    case normal
    case onboarding(stage: MAFooterRevealStage)
}
