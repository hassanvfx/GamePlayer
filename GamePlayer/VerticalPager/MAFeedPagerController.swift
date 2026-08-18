import UIKit

extension Notification.Name {
    static let verticalPagerDidSettlePage = Notification.Name("MADidSettlePage")
    static let verticalPagerFooterRenderModeDidChange = Notification.Name("MAFooterRenderModeDidChange")
    static let verticalPagerShouldAdvancePage = Notification.Name("MAShouldAdvancePage")
    static let verticalPagerOnboardingDidFinish = Notification.Name("MAOnboardingDidFinish")
}

enum MAFeedNotificationUserInfoKey {
    static let previousIndex = "previousIndex"
    static let currentIndex = "currentIndex"
    static let footerRenderMode = "footerRenderMode"
}

final class MAFeedPagerController: UIViewController {
    private enum MALayout {
        static let pageSpacing: CGFloat = 0
        static let dragCompletionProgressThreshold: CGFloat = 0.2
        static let dragVelocityThreshold: CGFloat = 500
        static let pullToRefreshTriggerOffset: CGFloat = 88
        static let pullToRefreshIndicatorTopInset: CGFloat = 20
        static let pullToRefreshIndicatorSize: CGFloat = 36
        static let pullToRefreshMinimumDisplayDuration: TimeInterval = 1.5
    }

    private let items: [MAPlayableGame]
    private let overlayConfiguration: MAOverlaySettings
    private let onHiddenHotAreaTap: ((MAPlayableGame) -> Void)?
    private let onActionBarInteraction: ((MAPlayableGame, MAFeedAction) -> Void)?
    private let onCurrentIndexChanged: ((Int, Int) -> Void)?
    private let onPullToRefresh: (() -> Void)?
    private var currentIndex = 0
    private var dragStartOffsetY: CGFloat = 0
    private var isInteractivelyDraggingPager = false
    private var pullToRefreshProgress: CGFloat = 0
    private var isRefreshing = false
    private var refreshStartDate: Date?
    private var footerRenderMode: MAFooterPresentation = .normal
    private var footerRenderModeObserver: NSObjectProtocol?
    private var advancePageObserver: NSObjectProtocol?
    private var onboardingDidFinishObserver: NSObjectProtocol?

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = MALayout.pageSpacing
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .black
        collectionView.isPagingEnabled = false
        collectionView.isScrollEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.decelerationRate = .fast
        collectionView.alwaysBounceVertical = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MAStagePlayerCell.self,
            forCellWithReuseIdentifier: MAStagePlayerCell.reuseIdentifier
        )
        return collectionView
    }()

    private let pullToRefreshIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.alpha = 0
        return indicator
    }()

    init(
        items: [MAPlayableGame],
        overlayConfiguration: MAOverlaySettings = .default,
        onHiddenHotAreaTap: ((MAPlayableGame) -> Void)? = nil,
        onActionBarInteraction: ((MAPlayableGame, MAFeedAction) -> Void)? = nil,
        onCurrentIndexChanged: ((Int, Int) -> Void)? = nil,
        onPullToRefresh: (() -> Void)? = nil
    ) {
        self.items = items
        self.overlayConfiguration = overlayConfiguration
        self.onHiddenHotAreaTap = onHiddenHotAreaTap
        self.onActionBarInteraction = onActionBarInteraction
        self.onCurrentIndexChanged = onCurrentIndexChanged
        self.onPullToRefresh = onPullToRefresh
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setUpCollectionView()
        setUpPullToRefreshIndicator()
        setUpPagerPanGesture()
        setUpOnboardingObservers()
    }

    deinit {
        if let footerRenderModeObserver {
            NotificationCenter.default.removeObserver(footerRenderModeObserver)
        }

        if let advancePageObserver {
            NotificationCenter.default.removeObserver(advancePageObserver)
        }

        if let onboardingDidFinishObserver {
            NotificationCenter.default.removeObserver(onboardingDidFinishObserver)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        let pageSize = collectionView.bounds.size
        if layout.itemSize != pageSize {
            layout.itemSize = pageSize
            layout.invalidateLayout()
        }
    }

    private func setUpCollectionView() {
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setUpPullToRefreshIndicator() {
        view.addSubview(pullToRefreshIndicator)

        NSLayoutConstraint.activate([
            pullToRefreshIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pullToRefreshIndicator.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: MALayout.pullToRefreshIndicatorTopInset
            ),
            pullToRefreshIndicator.widthAnchor.constraint(equalToConstant: MALayout.pullToRefreshIndicatorSize),
            pullToRefreshIndicator.heightAnchor.constraint(equalToConstant: MALayout.pullToRefreshIndicatorSize)
        ])
    }

    private func setUpPagerPanGesture() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePagerPan(_:)))
        panGestureRecognizer.delegate = self
        panGestureRecognizer.cancelsTouchesInView = true
        collectionView.addGestureRecognizer(panGestureRecognizer)
    }

    @objc
    private func handlePagerPan(_ gesture: UIPanGestureRecognizer) {
        let pageHeight = collectionView.bounds.height
        guard pageHeight > 0 else { return }

        switch gesture.state {
        case .began:
            dragStartOffsetY = collectionView.contentOffset.y
            isInteractivelyDraggingPager = true
            notifyVisibleCellsPageMovementDidBegin()

        case .changed:
            guard isInteractivelyDraggingPager else { return }

            let translationY = gesture.translation(in: collectionView).y
            let minOffsetY: CGFloat = 0
            let maxOffsetY = max(0, collectionView.contentSize.height - pageHeight)
            let proposedOffsetY = dragStartOffsetY - translationY

            if currentIndex == 0, dragStartOffsetY <= 0, translationY > 0 {
                let overpull = translationY
                pullToRefreshProgress = min(overpull / MALayout.pullToRefreshTriggerOffset, 1)
                updatePullToRefreshIndicator(isRefreshing: false)
                collectionView.contentOffset.y = 0
                return
            }

            pullToRefreshProgress = 0
            updatePullToRefreshIndicator(isRefreshing: false)

            let clampedOffsetY = min(max(proposedOffsetY, minOffsetY), maxOffsetY)
            collectionView.contentOffset.y = clampedOffsetY

        case .ended, .cancelled, .failed:
            guard isInteractivelyDraggingPager else { return }
            isInteractivelyDraggingPager = false
            finishInteractiveDrag(using: gesture, pageHeight: pageHeight)

        default:
            break
        }
    }

    private func finishInteractiveDrag(using gesture: UIPanGestureRecognizer, pageHeight: CGFloat) {
        let translationY = gesture.translation(in: collectionView).y

        if currentIndex == 0,
           dragStartOffsetY <= 0,
           translationY > 0,
           pullToRefreshProgress >= 1,
           !isRefreshing
        {
            beginPullToRefresh()
            snapToPage(at: currentIndex, animated: true)
            return
        }

        pullToRefreshProgress = 0
        updatePullToRefreshIndicator(isRefreshing: false)

        let velocityY = gesture.velocity(in: collectionView).y
        let progress = abs(translationY) / pageHeight

        let targetIndex: Int
        if translationY <= 0,
           progress >= MALayout.dragCompletionProgressThreshold || velocityY <= -MALayout.dragVelocityThreshold
        {
            targetIndex = min(currentIndex + 1, items.count - 1)
        } else if translationY > 0,
                  progress >= MALayout.dragCompletionProgressThreshold || velocityY >= MALayout.dragVelocityThreshold
        {
            targetIndex = max(currentIndex - 1, 0)
        } else {
            targetIndex = currentIndex
        }

        snapToPage(at: targetIndex, animated: true)
    }

    private func beginPullToRefresh() {
        isRefreshing = true
        refreshStartDate = Date()
        pullToRefreshProgress = 1
        updatePullToRefreshIndicator(isRefreshing: true)
        onPullToRefresh?()

        DispatchQueue.main.asyncAfter(deadline: .now() + MALayout.pullToRefreshMinimumDisplayDuration) { [weak self] in
            self?.endPullToRefreshIfNeeded()
        }
    }

    private func endPullToRefreshIfNeeded() {
        guard isRefreshing else { return }
        isRefreshing = false
        refreshStartDate = nil
        pullToRefreshProgress = 0
        updatePullToRefreshIndicator(isRefreshing: false)
    }

    private func updatePullToRefreshIndicator(isRefreshing: Bool) {
        let alpha = isRefreshing ? 1 : max(0, min(pullToRefreshProgress, 1))

        if isRefreshing {
            pullToRefreshIndicator.startAnimating()
        } else {
            pullToRefreshIndicator.stopAnimating()
        }

        UIView.animate(withDuration: 0.15) {
            self.pullToRefreshIndicator.alpha = alpha
            let scale = isRefreshing ? 1 : max(0.7, 0.7 + (0.3 * self.pullToRefreshProgress))
            self.pullToRefreshIndicator.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    private func snapToPage(at index: Int, animated: Bool) {
        let boundedIndex = max(0, min(items.count - 1, index))
        currentIndex = boundedIndex

        let targetOffset = CGPoint(x: 0, y: CGFloat(boundedIndex) * collectionView.bounds.height)
        collectionView.setContentOffset(targetOffset, animated: animated)

        if !animated {
            updateActiveCell()
        }
    }

    private func activeCellForGesture(at location: CGPoint) -> MAStagePlayerCell? {
        let currentIndexPath = IndexPath(item: currentIndex, section: 0)
        if let currentCell = collectionView.cellForItem(at: currentIndexPath) as? MAStagePlayerCell {
            let pointInCell = collectionView.convert(location, to: currentCell.contentView)
            if currentCell.contentView.bounds.contains(pointInCell) {
                return currentCell
            }
        }

        guard
            let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? MAStagePlayerCell
        else {
            return nil
        }

        return cell
    }

    func advanceToNextPage(animated: Bool) {
        snapToPage(at: currentIndex + 1, animated: animated)
    }

    private func setUpOnboardingObservers() {
        footerRenderModeObserver = NotificationCenter.default.addObserver(
            forName: .verticalPagerFooterRenderModeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let self,
                let footerRenderMode = notification
                .userInfo?[MAFeedNotificationUserInfoKey.footerRenderMode] as? MAFooterPresentation
            else {
                return
            }

            self.footerRenderMode = footerRenderMode
            self.applyFooterRenderModeToVisibleCells()
        }

        advancePageObserver = NotificationCenter.default.addObserver(
            forName: .verticalPagerShouldAdvancePage,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.advanceToNextPage(animated: true)
        }

        onboardingDidFinishObserver = NotificationCenter.default.addObserver(
            forName: .verticalPagerOnboardingDidFinish,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.footerRenderMode = .normal
            self?.applyFooterRenderModeToVisibleCells()
        }
    }

    private func notifyVisibleCellsPageMovementDidBegin() {
        for case let cell as MAStagePlayerCell in collectionView.visibleCells {
            cell.pageMovementDidBegin()
        }
    }

    private func notifyCurrentCellPageDidSettle() {
        let currentIndexPath = IndexPath(item: currentIndex, section: 0)
        guard let cell = collectionView.cellForItem(at: currentIndexPath) as? MAStagePlayerCell else {
            return
        }

        cell.pageDidSettle()
    }
}

extension MAFeedPagerController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MAStagePlayerCell.reuseIdentifier,
                for: indexPath
            ) as? MAStagePlayerCell
        else {
            return UICollectionViewCell()
        }

        cell.configure(
            with: items[indexPath.item],
            overlayConfiguration: overlayConfiguration,
            footerRenderMode: footerRenderMode,
            onHiddenHotAreaTap: onHiddenHotAreaTap,
            onActionBarInteraction: onActionBarInteraction
        )
        cell.applyPlaybackState(indexPath.item == currentIndex ? .primary : .inactive)

        return cell
    }
}

extension MAFeedPagerController: UICollectionViewDelegateFlowLayout {
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateActiveCell()
    }

    private func updateActiveCell() {
        let pageHeight = collectionView.bounds.height
        guard pageHeight > 0 else { return }

        let previousIndex = currentIndex
        let rawIndex = Int(round(collectionView.contentOffset.y / pageHeight))
        let boundedIndex = max(0, min(items.count - 1, rawIndex))
        currentIndex = boundedIndex
        applyPlaybackStateToVisibleCells()
        notifyCurrentCellPageDidSettle()

        NotificationCenter.default.post(
            name: .verticalPagerDidSettlePage,
            object: self,
            userInfo: [
                MAFeedNotificationUserInfoKey.previousIndex: previousIndex,
                MAFeedNotificationUserInfoKey.currentIndex: boundedIndex
            ]
        )

        guard previousIndex != boundedIndex else { return }
        onCurrentIndexChanged?(previousIndex, boundedIndex)
    }

    private func applyPlaybackStateToVisibleCells() {
        for case let cell as MAStagePlayerCell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell) else {
                continue
            }

            cell.applyPlaybackState(indexPath.item == currentIndex ? .primary : .inactive)
        }
    }

    private func applyFooterRenderModeToVisibleCells() {
        for case let cell as MAStagePlayerCell in collectionView.visibleCells {
            cell.applyFooterRenderMode(footerRenderMode)
        }
    }
}

extension MAFeedPagerController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: collectionView)
        guard let activeCell = activeCellForGesture(at: location) else {
            return false
        }

        let pointInCell = collectionView.convert(location, to: activeCell.contentView)
        return activeCell.isPointInFooterRegion(pointInCell)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }

        let velocity = panGestureRecognizer.velocity(in: collectionView)
        guard abs(velocity.y) > abs(velocity.x) else {
            return false
        }

        let location = panGestureRecognizer.location(in: collectionView)
        guard let activeCell = activeCellForGesture(at: location) else {
            return false
        }

        let pointInCell = collectionView.convert(location, to: activeCell.contentView)
        return activeCell.isPointInFooterRegion(pointInCell)
    }
}
