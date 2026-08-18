import UIKit

enum MAFeedGeometry {
    static let footerHeight: CGFloat = 120
    static let footerBackgroundColor = UIColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 0.94)
    static let footerHorizontalPadding: CGFloat = 16
    static let footerVerticalPadding: CGFloat = 14
    static let textSpacing: CGFloat = 4
    static let avatarSize: CGFloat = 34
    static let loadingIndicatorSize: CGFloat = 44
    static let textInsetFromAvatar: CGFloat = 12
    static let metadataTopPadding: CGFloat = 12
    static let footerAutoHideTranslationYOffset: CGFloat = footerHeight + 24
    static let footerAnimationDuration: TimeInterval = 0.28

    static let overlayHorizontalPadding: CGFloat = 16
    static let overlayBottomPadding: CGFloat = 12
    static let overlayTopPadding: CGFloat = 12
    static let overlayHeight: CGFloat = 110
    static let actionButtonSpacing: CGFloat = 12
    static let captionTopSpacing: CGFloat = 12
    static let actionBarAnimationDuration: TimeInterval = 0.32
    static let countdownHairlineHeight: CGFloat = 1
    static let countdownHairlineHorizontalInset: CGFloat = 10

    static let onboardingCardCornerRadius: CGFloat = 26
    static let onboardingCardHorizontalInset: CGFloat = 16
    static let onboardingCardBottomInset: CGFloat = 12
    static let onboardingCardInternalPadding: CGFloat = 16
    static let onboardingPulseSize: CGFloat = 52

    static let groupedActionsTrailingGapToChat: CGFloat = 28
    static let groupedActionsInternalHorizontalPadding: CGFloat = 12
    static let chatMinimumWidth: CGFloat = 124
    static let actionButtonHeight: CGFloat = 44

    static func footerFrame(in bounds: CGRect, safeAreaInsets: UIEdgeInsets) -> CGRect {
        CGRect(
            x: 0,
            y: bounds.height - safeAreaInsets.bottom - footerHeight,
            width: bounds.width,
            height: footerHeight
        )
    }

    static func onboardingCardFrame(in bounds: CGRect, safeAreaInsets: UIEdgeInsets) -> CGRect {
        let footerFrame = footerFrame(in: bounds, safeAreaInsets: safeAreaInsets)
        return footerFrame.insetBy(dx: onboardingCardHorizontalInset, dy: onboardingCardBottomInset)
    }

    static func actionBarContentFrame(in bounds: CGRect, safeAreaInsets: UIEdgeInsets) -> CGRect {
        let footerFrame = footerFrame(in: bounds, safeAreaInsets: safeAreaInsets)
        return CGRect(
            x: footerFrame.minX + overlayHorizontalPadding,
            y: footerFrame.minY + overlayTopPadding,
            width: footerFrame.width - (overlayHorizontalPadding * 2),
            height: footerFrame.height - overlayTopPadding - overlayBottomPadding
        )
    }

    static func likePulseCenter(in bounds: CGRect, safeAreaInsets: UIEdgeInsets) -> CGPoint {
        let contentFrame = actionBarContentFrame(in: bounds, safeAreaInsets: safeAreaInsets)
        let groupedWidth = max(
            0,
            contentFrame.width - chatMinimumWidth - groupedActionsTrailingGapToChat
        )
        let leadingInset = groupedActionsInternalHorizontalPadding
        let trailingInset = groupedActionsInternalHorizontalPadding
        let availableWidth = max(0, groupedWidth - leadingInset - trailingInset)
        let segmentWidth = availableWidth / 3
        let x = contentFrame.minX + leadingInset + (segmentWidth * 1.5)
        let y = contentFrame.minY + (actionButtonHeight / 2)
        return CGPoint(x: x, y: y)
    }

    static func chatPulseCenter(in bounds: CGRect, safeAreaInsets: UIEdgeInsets) -> CGPoint {
        let contentFrame = actionBarContentFrame(in: bounds, safeAreaInsets: safeAreaInsets)
        let x = contentFrame.maxX - (chatMinimumWidth / 2)
        let y = contentFrame.minY + (actionButtonHeight / 2)
        return CGPoint(x: x, y: y)
    }
}
