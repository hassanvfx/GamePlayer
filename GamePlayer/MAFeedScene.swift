import SwiftUI
import UIKit

struct MAFeedScene: UIViewControllerRepresentable {
    var items: [MAPlayableGame] = MAArcadeCatalog.all

    func makeUIViewController(context: Context) -> MAContainerViewController {
        MAContainerViewController(items: items)
    }

    func updateUIViewController(_ uiViewController: MAContainerViewController, context: Context) {
        uiViewController.update(items: items)
    }
}

extension MAFeedScene {
    final class MAContainerViewController: UIViewController {
        private let overlayConfiguration = MAOverlaySettings(
            autoHideDelay: nil,
            hiddenHotArea: nil,
            autoShowActionBar: true,
            actionBarIdleDelay: 1
        )

        private var items: [MAPlayableGame]
        private var pagerViewController: MAFeedPagerController?
        private let onboardingOverlayView = MAWalkthroughCurtain()
        private var hasStartedOnboarding = false
        private var onboardingDidFinishObserver: NSObjectProtocol?
        private var hasPresentedOnboardingCompletionAlert = false

        init(items: [MAPlayableGame]) {
            self.items = items
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        deinit {
            if let onboardingDidFinishObserver {
                NotificationCenter.default.removeObserver(onboardingDidFinishObserver)
            }
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            embedPager()
            setUpOnboardingOverlay()
            setUpOnboardingCompletionObserver()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            startOnboardingIfNeeded()
        }

        func update(items: [MAPlayableGame]) {
            guard self.items != items else { return }
            self.items = items
            hasStartedOnboarding = false
            hasPresentedOnboardingCompletionAlert = false
            replacePager()
        }

        private func embedPager() {
            let pagerViewController = MAFeedPagerController(
                items: items,
                overlayConfiguration: overlayConfiguration,
                onHiddenHotAreaTap: { [weak self] item in
                    self?.presentHotAreaAlert(for: item)
                },
                onActionBarInteraction: { [weak self] item, action in
                    self?.presentActionAlert(for: item, action: action)
                },
                onCurrentIndexChanged: { [weak self] _, currentIndex in
                    self?.onboardingOverlayView.handlePageChange(to: currentIndex)
                }
            )

            addChild(pagerViewController)
            view.addSubview(pagerViewController.view)
            pagerViewController.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                pagerViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                pagerViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pagerViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                pagerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            pagerViewController.didMove(toParent: self)
            self.pagerViewController = pagerViewController
            view.bringSubviewToFront(onboardingOverlayView)
        }

        private func setUpOnboardingOverlay() {
            onboardingOverlayView.onCompletion = { [weak self] completedStepID in
                self?.presentOnboardingCompletionAlert(
                    message: "Completed step: \(String(describing: completedStepID))"
                )
            }

            view.addSubview(onboardingOverlayView)

            NSLayoutConstraint.activate([
                onboardingOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
                onboardingOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                onboardingOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                onboardingOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            view.bringSubviewToFront(onboardingOverlayView)
        }

        private func startOnboardingIfNeeded() {
            guard !hasStartedOnboarding else { return }
            hasStartedOnboarding = true
            hasPresentedOnboardingCompletionAlert = false
            view.layoutIfNeeded()
            onboardingOverlayView.start(at: 0)
            view.bringSubviewToFront(onboardingOverlayView)
        }

        private func setUpOnboardingCompletionObserver() {
            onboardingDidFinishObserver = NotificationCenter.default.addObserver(
                forName: .verticalPagerOnboardingDidFinish,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.presentOnboardingCompletionAlert(
                    message: "Received onboarding completion notification."
                )
            }
        }

        private func presentOnboardingCompletionAlert(message: String) {
            guard !hasPresentedOnboardingCompletionAlert else { return }
            hasPresentedOnboardingCompletionAlert = true
            presentAlert(title: "Onboarding Complete", message: message)
        }

        private func replacePager() {
            guard let pagerViewController else {
                embedPager()
                return
            }

            pagerViewController.willMove(toParent: nil)
            pagerViewController.view.removeFromSuperview()
            pagerViewController.removeFromParent()
            self.pagerViewController = nil

            embedPager()
            startOnboardingIfNeeded()
        }

        private func presentHotAreaAlert(for item: MAPlayableGame) {
            let title = item.title ?? item.username ?? "Hidden Hot Area"
            let message = item.description ?? item.webURL.absoluteString
            presentAlert(title: title, message: message)
        }

        private func presentActionAlert(for item: MAPlayableGame, action: MAFeedAction) {
            let actionTitle: String
            switch action {
            case .like:
                actionTitle = "Save"
            case .share:
                actionTitle = "Share"
            case .more:
                actionTitle = "More"
            case .remix:
                actionTitle = "Remix"
            case .chat:
                actionTitle = "Chat"
            }

            let itemTitle = item.title ?? item.username ?? "Item"
            presentAlert(title: actionTitle, message: itemTitle)
        }

        private func presentAlert(title: String, message: String) {
            let alertController = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default))

            if let presentedViewController {
                presentedViewController.dismiss(animated: false) { [weak self] in
                    self?.present(alertController, animated: true)
                }
            } else {
                present(alertController, animated: true)
            }
        }
    }
}

#Preview("Game Feed") {
    MAFeedScene(items: MAArcadeCatalog.preview)
        .ignoresSafeArea()
}
