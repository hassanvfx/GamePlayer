import UIKit

final class MAWalkthroughCard: UIControl {
    enum MAIconAnimationStyle {
        case swipeUp
        case heartbeat
        case float
        case ring
        case none
    }

    private enum MALayout {
        static let iconSize: CGFloat = 30
        static let iconContainerSize: CGFloat = 60
        static let textSpacing: CGFloat = 4
        static let stackSpacing: CGFloat = 12
        static let buttonHeight: CGFloat = 38
        static let buttonHorizontalPadding: CGFloat = 14
        static let borderWidth: CGFloat = 1
        static let shadowRadius: CGFloat = 18
        static let shadowOpacity: Float = 0.16
    }

    private enum MAPalette {
        static let vanilla = UIColor(red: 1, green: 0.98, blue: 0.93, alpha: 0.98)
        static let vanillaHighlight = UIColor(red: 1, green: 0.95, blue: 0.84, alpha: 0.96)
        static let vanillaBorder = UIColor(red: 0.76, green: 0.62, blue: 0.39, alpha: 0.22)
        static let ink = UIColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 1)
        static let secondaryInk = UIColor(red: 0.34, green: 0.30, blue: 0.25, alpha: 1)
        static let appleBlue = UIColor(red: 0, green: 0.48, blue: 1, alpha: 1)
        static let tangerine = UIColor(red: 0.95, green: 0.49, blue: 0.09, alpha: 1)
    }

    private let gradientLayer = CAGradientLayer()
    private let highlightLayer = CAGradientLayer()

    private let blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()

    private let tintOverlayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = MAPalette.vanilla.withAlphaComponent(0.86)
        view.isUserInteractionEnabled = false
        return view
    }()

    private let borderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderWidth = MALayout.borderWidth
        view.layer.borderColor = MAPalette.vanillaBorder.cgColor
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()

    private let iconContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = MAPalette.appleBlue.withAlphaComponent(0.12)
        view.layer.cornerRadius = MALayout.iconContainerSize / 2
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()

    private let iconGlowView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = MAPalette.appleBlue.withAlphaComponent(0.15)
        view.layer.shadowColor = MAPalette.appleBlue.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 12
        view.layer.shadowOffset = .zero
        view.layer.cornerRadius = MALayout.iconContainerSize / 2
        view.isUserInteractionEnabled = false
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = MAPalette.appleBlue
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = MAPalette.ink
        label.numberOfLines = 1
        label.isUserInteractionEnabled = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = MAPalette.secondaryInk
        label.numberOfLines = 1
        label.isUserInteractionEnabled = false
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = MALayout.textSpacing
        stack.isUserInteractionEnabled = false
        return stack
    }()

    private let swipeArrowImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.up"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = MAPalette.appleBlue
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    private let swipeLineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = MAPalette.appleBlue.withAlphaComponent(0.5)
        view.layer.cornerRadius = 1.5
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var swipeHintStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [swipeArrowImageView, swipeLineView])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.isUserInteractionEnabled = false
        return stack
    }()

    private let primaryButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = UIColor.white
        configuration.baseForegroundColor = .black
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: MALayout.buttonHorizontalPadding,
            bottom: 8,
            trailing: MALayout.buttonHorizontalPadding
        )

        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    private var currentAnimationStyle: MAIconAnimationStyle = .none

    var onPrimaryAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        highlightLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
        highlightLayer.cornerRadius = layer.cornerRadius
        borderView.layer.cornerRadius = layer.cornerRadius
        blurView.layer.cornerRadius = layer.cornerRadius
        iconGlowView.layer.cornerRadius = MALayout.iconContainerSize / 2
    }

    func configure(step: MAWalkthroughStep) {
        titleLabel.text = step.title
        messageLabel.text = step.message
        iconImageView.image = UIImage(systemName: step.symbolName)
        accessibilityLabel = "\(step.title). \(step.message)"
        applyAccentColor(for: step.id)
        swipeHintStackView.isHidden = step.id != .swipeUp

        switch step.id {
        case .swipeUp:
            currentAnimationStyle = .swipeUp
        case .save:
            currentAnimationStyle = .heartbeat
        case .remix:
            currentAnimationStyle = .float
        case .finalize:
            currentAnimationStyle = .ring
        }

        if step.showsPrimaryButton, let primaryButtonTitle = step.primaryButtonTitle {
            primaryButton.isHidden = false
            primaryButton.configuration?.title = primaryButtonTitle
        } else {
            primaryButton.isHidden = true
            primaryButton.configuration?.title = nil
        }

        applyIconAnimation()
    }

    private func setUpViews() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = MAFeedGeometry.onboardingCardCornerRadius
        layer.cornerCurve = .continuous
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = MALayout.shadowOpacity
        layer.shadowRadius = MALayout.shadowRadius
        layer.shadowOffset = CGSize(width: 0, height: 12)

        gradientLayer.colors = [
            MAPalette.vanilla.cgColor,
            MAPalette.vanillaHighlight.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)

        highlightLayer.colors = [
            UIColor.white.withAlphaComponent(0.55).cgColor,
            UIColor.clear.cgColor
        ]
        highlightLayer.startPoint = CGPoint(x: 0.15, y: 0)
        highlightLayer.endPoint = CGPoint(x: 0.8, y: 0.55)
        layer.insertSublayer(highlightLayer, above: gradientLayer)

        addSubview(blurView)
        addSubview(borderView)
        blurView.contentView.addSubview(tintOverlayView)
        blurView.contentView.addSubview(iconGlowView)
        blurView.contentView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        blurView.contentView.addSubview(textStackView)
        blurView.contentView.addSubview(swipeHintStackView)
        blurView.contentView.addSubview(primaryButton)

        addTarget(self, action: #selector(handleTouchDownDismiss), for: .touchDown)
        primaryButton.addTarget(self, action: #selector(handlePrimaryButtonTap), for: .touchUpInside)

        swipeLineView.widthAnchor.constraint(equalToConstant: 3).isActive = true
        swipeLineView.heightAnchor.constraint(equalToConstant: 18).isActive = true

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            borderView.topAnchor.constraint(equalTo: topAnchor),
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor),

            tintOverlayView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
            tintOverlayView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            tintOverlayView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
            tintOverlayView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor),

            iconGlowView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconGlowView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconGlowView.widthAnchor.constraint(equalToConstant: MALayout.iconContainerSize),
            iconGlowView.heightAnchor.constraint(equalToConstant: MALayout.iconContainerSize),

            iconContainerView.leadingAnchor.constraint(
                equalTo: blurView.contentView.leadingAnchor,
                constant: MAFeedGeometry.onboardingCardInternalPadding
            ),
            iconContainerView.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: MALayout.iconContainerSize),
            iconContainerView.heightAnchor.constraint(equalToConstant: MALayout.iconContainerSize),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: MALayout.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: MALayout.iconSize),

            textStackView.leadingAnchor.constraint(
                equalTo: iconContainerView.trailingAnchor,
                constant: MALayout.stackSpacing
            ),
            textStackView.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),

            swipeHintStackView.leadingAnchor.constraint(equalTo: textStackView.trailingAnchor, constant: 10),
            swipeHintStackView.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),

            primaryButton.leadingAnchor.constraint(greaterThanOrEqualTo: textStackView.trailingAnchor, constant: 12),
            primaryButton.trailingAnchor.constraint(
                equalTo: blurView.contentView.trailingAnchor,
                constant: -MAFeedGeometry.onboardingCardInternalPadding
            ),
            primaryButton.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            primaryButton.heightAnchor.constraint(equalToConstant: MALayout.buttonHeight),

            textStackView.trailingAnchor.constraint(lessThanOrEqualTo: primaryButton.leadingAnchor, constant: -12),
            blurView.contentView.trailingAnchor.constraint(
                greaterThanOrEqualTo: swipeHintStackView.trailingAnchor,
                constant: MAFeedGeometry.onboardingCardInternalPadding
            )
        ])
    }

    private func applyAccentColor(for stepID: MAWalkthroughStepID) {
        let accentColor: UIColor

        switch stepID {
        case .swipeUp:
            accentColor = MAPalette.appleBlue
        case .save:
            accentColor = .systemPink
        case .remix:
            accentColor = MAPalette.tangerine
        case .finalize:
            accentColor = MAPalette.appleBlue
        }

        iconImageView.tintColor = accentColor
        iconContainerView.backgroundColor = accentColor.withAlphaComponent(0.12)
        iconGlowView.backgroundColor = accentColor.withAlphaComponent(0.15)
        iconGlowView.layer.shadowColor = accentColor.cgColor
        swipeArrowImageView.tintColor = accentColor
        swipeLineView.backgroundColor = accentColor.withAlphaComponent(0.5)
    }

    private func applyIconAnimation() {
        iconContainerView.layer.removeAllAnimations()
        iconImageView.layer.removeAllAnimations()
        iconGlowView.layer.removeAllAnimations()
        swipeArrowImageView.layer.removeAllAnimations()
        swipeLineView.layer.removeAllAnimations()

        iconContainerView.transform = .identity
        iconImageView.transform = .identity
        iconGlowView.transform = .identity
        swipeArrowImageView.transform = .identity
        swipeLineView.transform = .identity

        switch currentAnimationStyle {
        case .swipeUp:
            UIView.animate(
                withDuration: 0.9,
                delay: 0,
                options: [.repeat, .autoreverse, .curveEaseInOut, .allowUserInteraction]
            ) {
                self.iconContainerView.transform = CGAffineTransform(translationX: 0, y: -5)
                self.swipeArrowImageView.transform = CGAffineTransform(translationX: 0, y: -5)
                self.swipeLineView.transform = CGAffineTransform(translationX: 0, y: -3)
            }

        case .heartbeat:
            UIView.animate(
                withDuration: 0.55,
                delay: 0,
                options: [.repeat, .autoreverse, .curveEaseInOut, .allowUserInteraction]
            ) {
                self.iconContainerView.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
                self.iconGlowView.transform = CGAffineTransform(scaleX: 1.16, y: 1.16)
            }

        case .float:
            UIView.animate(
                withDuration: 1.2,
                delay: 0,
                options: [.repeat, .autoreverse, .curveEaseInOut, .allowUserInteraction]
            ) {
                self.iconContainerView.transform = CGAffineTransform(translationX: 0, y: -4)
                self.iconGlowView.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
            }

        case .ring:
            UIView.animateKeyframes(
                withDuration: 0.95,
                delay: 0,
                options: [.repeat, .calculationModeLinear, .allowUserInteraction]
            ) {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2) {
                    self.iconImageView.transform = CGAffineTransform(rotationAngle: -0.18)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2) {
                    self.iconImageView.transform = CGAffineTransform(rotationAngle: 0.18)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.2) {
                    self.iconImageView.transform = CGAffineTransform(rotationAngle: -0.1)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.2) {
                    self.iconImageView.transform = CGAffineTransform(rotationAngle: 0.1)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2) {
                    self.iconImageView.transform = .identity
                }
            }

        case .none:
            break
        }
    }

    @objc
    private func handleTouchDownDismiss() {
        sendActions(for: .primaryActionTriggered)
    }

    @objc
    private func handlePrimaryButtonTap() {
        onPrimaryAction?()
    }
}
