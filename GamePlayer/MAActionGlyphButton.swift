import UIKit

final class MAActionGlyphButton: UIControl {
    private let imageView = UIImageView()
    private let countLabel = UILabel()

    init(symbolName: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: symbolName)
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        countLabel.textColor = .white
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        addSubview(countLabel)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 32),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 18),
            imageView.heightAnchor.constraint(equalToConstant: 18),
            countLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 5),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(count: Int?) {
        countLabel.text = count.map { $0 >= 1000 ? String(format: "%.1fK", Double($0) / 1000) : "\($0)" }
        countLabel.isHidden = count == nil
    }
}
