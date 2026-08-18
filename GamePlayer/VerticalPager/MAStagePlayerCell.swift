import UIKit
import WebKit

final class MAStagePlayerCell: UICollectionViewCell {
    enum MAPlaybackState: Equatable { case inactive, primary }

    static let reuseIdentifier = "MAStagePlayerCell"
    var onHiddenHotAreaTap: ((MAPlayableGame) -> Void)?
    var onActionBarInteraction: ((MAPlayableGame, MAFeedAction) -> Void)?

    private let webContainer = UIView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    private let footer = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    private let avatar = UIImageView()
    private let creatorLabel = UILabel()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let likeButton = MAActionGlyphButton(symbolName: "heart.fill")
    private let shareButton = MAActionGlyphButton(symbolName: "square.and.arrow.up")
    private let moreButton = MAActionGlyphButton(symbolName: "ellipsis")
    private var webView: WKWebView!
    private var avatarTask: URLSessionDataTask?
    private var item: MAPlayableGame?
    private var playbackState: MAPlaybackState = .inactive
    private var hasLoadedItem = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpInterface()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarTask?.cancel()
        avatarTask = nil
        item = nil
        playbackState = .inactive
        hasLoadedItem = false
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
        resetInterface()
    }

    func configure(with item: MAPlayableGame) {
        guard self.item != item else { return }
        prepareForReuse()
        self.item = item
        titleLabel.text = item.title
        descriptionLabel.text = item.description
        descriptionLabel.isHidden = item.description == nil
        creatorLabel.text = item.username
        creatorLabel.isHidden = item.username == nil
        likeButton.configure(count: item.likeCount)
        shareButton.configure(count: item.shareCount)
        moreButton.configure(count: item.chatCount)
        if let avatarURL = item.avatarURL {
            avatarTask = MAAvatarImageLoader.shared
                .load(from: avatarURL) { [weak self] image in self?.avatar.image = image }
        }
    }

    func configure(
        with item: MAPlayableGame,
        overlayConfiguration: MAOverlaySettings,
        footerRenderMode: MAFooterPresentation,
        onHiddenHotAreaTap: ((MAPlayableGame) -> Void)?,
        onActionBarInteraction: ((MAPlayableGame, MAFeedAction) -> Void)?
    ) {
        self.onHiddenHotAreaTap = onHiddenHotAreaTap
        self.onActionBarInteraction = onActionBarInteraction
        configure(with: item)
        applyFooterRenderMode(footerRenderMode)
    }

    func applyPlaybackState(_ state: MAPlaybackState) {
        playbackState = state
        let isPrimary = state == .primary
        webView.isHidden = !isPrimary
        webView.isUserInteractionEnabled = isPrimary
        if isPrimary {
            loadIfNecessary()
        }
    }

    func applyFooterRenderMode(_ mode: MAFooterPresentation) {
        footer.isHidden = mode != .normal
    }

    func isPointInFooterRegion(_ point: CGPoint) -> Bool {
        footer.frame.contains(point)
    }

    func pageMovementDidBegin() {}
    func pageDidSettle() {}

    private func loadIfNecessary() {
        guard !hasLoadedItem, let item else { return }
        hasLoadedItem = true
        spinner.startAnimating()
        webView.load(URLRequest(url: item.webURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20))
    }

    private func setUpInterface() {
        contentView.backgroundColor = .black
        [webContainer, footer]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview($0) }
        spinner.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.text = "Unable to load this game"
        errorLabel.textColor = .white
        errorLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        webContainer.addSubview(spinner)
        webContainer.addSubview(errorLabel)
        footer.contentView.addSubview(avatar)
        footer.contentView.addSubview(creatorLabel)
        footer.contentView.addSubview(titleLabel)
        footer.contentView.addSubview(descriptionLabel)
        let actions = UIStackView(arrangedSubviews: [likeButton, shareButton, moreButton])
        actions.axis = .vertical; actions.spacing = 8; actions.translatesAutoresizingMaskIntoConstraints = false
        footer.contentView.addSubview(actions)
        [avatar, creatorLabel, titleLabel, descriptionLabel]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        avatar.image = UIImage(systemName: "person.crop.circle.fill"); avatar.tintColor = .white; avatar
            .contentMode = .scaleAspectFit
        creatorLabel.font = .systemFont(ofSize: 13, weight: .semibold); creatorLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold); titleLabel.textColor = .white
        descriptionLabel.font = .systemFont(ofSize: 13); descriptionLabel.textColor = UIColor.white
            .withAlphaComponent(0.78); descriptionLabel.numberOfLines = 2
        likeButton.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(handleShare), for: .touchUpInside)
        moreButton.addTarget(self, action: #selector(handleMore), for: .touchUpInside)
        replaceWebView()
        NSLayoutConstraint.activate([
            webContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            webContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            webContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            webContainer.bottomAnchor.constraint(equalTo: footer.topAnchor),
            footer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            footer.heightAnchor.constraint(equalToConstant: 154),
            spinner.centerXAnchor.constraint(equalTo: webContainer.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: webContainer.centerYAnchor),
            errorLabel.centerXAnchor.constraint(equalTo: webContainer.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: webContainer.centerYAnchor),
            avatar.leadingAnchor.constraint(equalTo: footer.contentView.leadingAnchor, constant: 16),
            avatar.topAnchor.constraint(
                equalTo: footer.contentView.topAnchor,
                constant: 18
            ), avatar.widthAnchor.constraint(equalToConstant: 36),
            avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor),
            creatorLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
            creatorLabel.topAnchor.constraint(equalTo: avatar.topAnchor), creatorLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: actions.leadingAnchor,
                constant: -12
            ),
            titleLabel.leadingAnchor.constraint(equalTo: creatorLabel.leadingAnchor), titleLabel.topAnchor.constraint(
                equalTo: creatorLabel.bottomAnchor,
                constant: 4
            ), titleLabel.trailingAnchor.constraint(equalTo: creatorLabel.trailingAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: creatorLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 4
            ), descriptionLabel.trailingAnchor.constraint(equalTo: creatorLabel.trailingAnchor),
            actions.trailingAnchor.constraint(equalTo: footer.contentView.trailingAnchor, constant: -16),
            actions.centerYAnchor.constraint(equalTo: footer.contentView.centerYAnchor)
        ])
    }

    private func replaceWebView() {
        webView?.removeFromSuperview()
        webView = MAWebViewFactory.make(navigationDelegate: self)
        webContainer.insertSubview(webView, at: 0)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: webContainer.topAnchor),
            webView.leadingAnchor.constraint(equalTo: webContainer.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webContainer.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: webContainer.bottomAnchor)
        ])
    }

    private func resetInterface() {
        spinner.stopAnimating(); errorLabel.isHidden = true; webView.isHidden = true
    }

    @objc private func handleLike() {
        perform(.like)
    }

    @objc private func handleShare() {
        perform(.share)
    }

    @objc private func handleMore() {
        perform(.more)
    }

    private func perform(_ action: MAFeedAction) {
        item.map { onActionBarInteraction?($0, action) }
    }
}

extension MAStagePlayerCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating(); errorLabel.isHidden = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating(); errorLabel.isHidden = false
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating(); errorLabel.isHidden = false
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        decisionHandler(MAWebNavigationPolicy.decision(for: navigationAction.request.url))
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        decisionHandler(MAWebNavigationPolicy.decision(for: navigationResponse.response))
    }
}
