import UIKit

final class MAWalkthroughCurtain: UIView {
    private enum MALayout {
        static let animationDuration: TimeInterval = 0.22
        static let pulseAnimationDuration: TimeInterval = 1.15
        static let dismissSwipeThreshold: CGFloat = 18
        static let dimAlpha: CGFloat = 0.06
        static let spotlightRingLineWidth: CGFloat = 2
    }

    private let steps: [MAWalkthroughStep]
    private let dimView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(MALayout.dimAlpha)
        view.isUserInteractionEnabled = false
        return view
    }()

    private let cardView = MAWalkthroughCard()
    private let pulseRingView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.95).cgColor
        view.layer.borderWidth = MALayout.spotlightRingLineWidth
        view.layer.shadowColor = UIColor.white.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 14
        view.layer.shadowOffset = .zero
        view.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        view.isUserInteractionEnabled = false
        view.alpha = 0
        return view
    }()

    private var currentStep: MAWalkthroughStep?
    private var dismissedStepIDs = Set<MAWalkthroughStepID>()
    private var currentPageIndex = 0
    private var cardBottomConstraint: NSLayoutConstraint?
    private var pulseCenterXConstraint: NSLayoutConstraint?
    private var pulseCenterYConstraint: NSLayoutConstraint?
    private var pulseSizeConstraint: NSLayoutConstraint?
    private var pageObservationToken: NSObjectProtocol?

    var onCompletion: ((MAWalkthroughStepID) -> Void)?

    init(steps: [MAWalkthroughStep] = MAWalkthroughStep.default) {
        self.steps = steps.sorted { $0.pageIndex < $1.pageIndex }
        super.init(frame: .zero)
        setUpViews()
        setUpGestures()
        setUpPageObservation()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let pageObservationToken {
            NotificationCenter.default.removeObserver(pageObservationToken)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCardLayout()
        updatePulseLayout()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !isHidden, alpha > 0.01, let currentStep else {
            return false
        }

        if cardView.frame.contains(point) {
            return true
        }

        switch currentStep.highlightTarget {
        case .none:
            return false
        case .like, .chat:
            return pulseRingView.frame.insetBy(dx: -12, dy: -12).contains(point)
        }
    }

    func start(at pageIndex: Int) {
        currentPageIndex = pageIndex
        dismissedStepIDs.removeAll()
        postFooterRenderMode(.onboarding(stage: .hidden))
        showStepIfNeeded(for: pageIndex, animated: false)
    }

    func handlePageChange(to pageIndex: Int) {
        currentPageIndex = pageIndex

        if dismissedStepIDs.contains(.remix) {
            finishOnboarding()
            return
        }

        showStepIfNeeded(for: pageIndex, animated: true)
    }

    private func setUpPageObservation() {
        pageObservationToken = NotificationCenter.default.addObserver(
            forName: .verticalPagerDidSettlePage,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let self,
                let currentIndex = notification.userInfo?[MAFeedNotificationUserInfoKey.currentIndex] as? Int
            else {
                return
            }

            self.handlePageChange(to: currentIndex)
        }
    }

    private func setUpViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        addSubview(dimView)
        addSubview(pulseRingView)
        addSubview(cardView)

        cardView.alpha = 0
        cardView.transform = CGAffineTransform(translationX: 0, y: 16)
        cardView.addTarget(self, action: #selector(handleCardTap), for: .primaryActionTriggered)
        cardView.onPrimaryAction = { [weak self] in
            self?.dismissCurrentStep()
        }

        let footerBottomInset = MAFeedGeometry.onboardingCardBottomInset + safeAreaInsets.bottom
        cardBottomConstraint = cardView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -footerBottomInset)
        pulseCenterXConstraint = pulseRingView.centerXAnchor.constraint(equalTo: leadingAnchor)
        pulseCenterYConstraint = pulseRingView.centerYAnchor.constraint(equalTo: topAnchor)
        pulseSizeConstraint = pulseRingView.widthAnchor.constraint(equalToConstant: MAFeedGeometry.onboardingPulseSize)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            cardView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: MAFeedGeometry.onboardingCardHorizontalInset
            ),
            cardView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -MAFeedGeometry.onboardingCardHorizontalInset
            ),
            cardBottomConstraint!,
            cardView.heightAnchor.constraint(
                equalToConstant: MAFeedGeometry.footerHeight - (MAFeedGeometry.onboardingCardBottomInset * 2)
            ),

            pulseCenterXConstraint!,
            pulseCenterYConstraint!,
            pulseSizeConstraint!,
            pulseRingView.heightAnchor.constraint(equalTo: pulseRingView.widthAnchor)
        ])
    }

    private func setUpGestures() {
        let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCardPan(_:)))
        swipeGesture.maximumNumberOfTouches = 1
        cardView.addGestureRecognizer(swipeGesture)
    }

    private func showStepIfNeeded(for pageIndex: Int, animated: Bool) {
        guard let nextStep = nextEligibleStep(for: pageIndex) else {
            hideCurrentStep(animated: animated)
            return
        }

        if !nextStep.isVisible {
            currentStep = nextStep
            completeCurrentStep(nextStep.id)
            return
        }

        postFooterRenderMode(.normal)

        let isSameStep = currentStep?.id == nextStep.id
        currentStep = nextStep
        cardView.configure(step: nextStep)
        updateCardLayout()
        updatePulseLayout()
        updatePulseVisibility(animated: animated)

        guard !isSameStep || cardView.alpha <= 0.01 else { return }

        let animations = {
            self.cardView.alpha = 1
            self.cardView.transform = .identity
        }

        if animated {
            cardView.transform = CGAffineTransform(translationX: 0, y: 16)
            UIView.animate(
                withDuration: MALayout.animationDuration,
                delay: 0,
                options: [.curveEaseOut]
            ) {
                animations()
            }
        } else {
            animations()
        }
    }

    private func hideCurrentStep(animated: Bool) {
        currentStep = nil
        let animations = {
            self.cardView.alpha = 0
            self.cardView.transform = CGAffineTransform(translationX: 0, y: 14)
            self.pulseRingView.alpha = 0
        }

        if animated {
            UIView.animate(withDuration: MALayout.animationDuration, animations: animations)
        } else {
            animations()
        }
    }

    private func nextEligibleStep(for pageIndex: Int) -> MAWalkthroughStep? {
        guard let step = steps.first(where: { $0.pageIndex == pageIndex }) else {
            return nil
        }

        guard !dismissedStepIDs.contains(step.id) else {
            return nil
        }

        return step
    }

    private func dismissCurrentStep() {
        guard let currentStep else { return }
        completeCurrentStep(currentStep.id)
    }

    private func completeCurrentStep(_ completedStepID: MAWalkthroughStepID) {
        dismissedStepIDs.insert(completedStepID)
        hideCurrentStep(animated: true)

        switch completedStepID {
        case .swipeUp:
            postFooterRenderMode(.normal)
            NotificationCenter.default.post(name: .verticalPagerShouldAdvancePage, object: self)

        case .save:
            postFooterRenderMode(.normal)
            NotificationCenter.default.post(name: .verticalPagerShouldAdvancePage, object: self)

        case .remix, .finalize:
            finishOnboarding()
            onCompletion?(completedStepID)
        }
    }

    private func finishOnboarding() {
        hideCurrentStep(animated: true)
        postFooterRenderMode(.normal)
        NotificationCenter.default.post(name: .verticalPagerOnboardingDidFinish, object: self)
    }

    private func postFooterRenderMode(_ renderMode: MAFooterPresentation) {
        NotificationCenter.default.post(
            name: .verticalPagerFooterRenderModeDidChange,
            object: self,
            userInfo: [
                MAFeedNotificationUserInfoKey.footerRenderMode: renderMode
            ]
        )
    }

    private func updateCardLayout() {
        cardBottomConstraint?.constant = -(MAFeedGeometry.onboardingCardBottomInset + safeAreaInsets.bottom)
    }

    private func updatePulseLayout() {
        guard let currentStep else { return }

        let center: CGPoint?
        switch currentStep.highlightTarget {
        case .none:
            center = nil
        case .like:
            center = MAFeedGeometry.likePulseCenter(in: bounds, safeAreaInsets: safeAreaInsets)
        case .chat:
            center = MAFeedGeometry.chatPulseCenter(in: bounds, safeAreaInsets: safeAreaInsets)
        }

        guard let center else {
            pulseRingView.layer.cornerRadius = 0
            pulseCenterXConstraint?.constant = 0
            pulseCenterYConstraint?.constant = 0
            return
        }

        let size = MAFeedGeometry.onboardingPulseSize
        pulseCenterXConstraint?.constant = center.x
        pulseCenterYConstraint?.constant = center.y
        pulseSizeConstraint?.constant = size
        pulseRingView.layer.cornerRadius = size / 2
    }

    private func updatePulseVisibility(animated: Bool) {
        guard let currentStep else {
            pulseRingView.alpha = 0
            pulseRingView.layer.removeAllAnimations()
            return
        }

        switch currentStep.highlightTarget {
        case .none:
            pulseRingView.alpha = 0
            pulseRingView.layer.removeAllAnimations()
            pulseRingView.transform = .identity

        case .like, .chat:
            pulseRingView.layer.removeAllAnimations()
            let showPulse = {
                self.pulseRingView.alpha = 1
            }

            if animated {
                UIView.animate(withDuration: MALayout.animationDuration, animations: showPulse)
            } else {
                showPulse()
            }

            UIView.animate(
                withDuration: MALayout.pulseAnimationDuration,
                delay: 0,
                options: [.repeat, .autoreverse, .curveEaseInOut, .allowUserInteraction]
            ) {
                self.pulseRingView.transform = CGAffineTransform(scaleX: 1.14, y: 1.14)
                self.pulseRingView.alpha = 0.55
            }
        }
    }

    @objc
    private func handleCardTap() {
        guard let currentStep else { return }

        switch currentStep.id {
        case .swipeUp:
            return
        case .save, .remix, .finalize:
            dismissCurrentStep()
        }
    }

    @objc
    private func handleCardPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: cardView)

        switch gestureRecognizer.state {
        case .changed:
            let offsetY = min(0, translation.y)
            cardView.transform = CGAffineTransform(translationX: 0, y: offsetY)
        case .ended, .cancelled, .failed:
            if translation.y < -MALayout.dismissSwipeThreshold, currentStep?.id == .swipeUp {
                dismissCurrentStep()
            } else {
                UIView.animate(withDuration: MALayout.animationDuration) {
                    self.cardView.transform = .identity
                }
            }
        default:
            break
        }
    }
}
