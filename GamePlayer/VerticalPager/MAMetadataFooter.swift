import SwiftUI
import UIKit

private let normalFooterAvatarImageCache = NSCache<NSURL, UIImage>()

struct MAMetadataFooter: View {
    let item: MAPlayableGame
    var titleOverride: String? = nil
    var onLikeTap: (() -> Void)? = nil
    var onShareTap: (() -> Void)? = nil
    var onMoreTap: (() -> Void)? = nil
    var onRemixTap: (() -> Void)? = nil

    @State private var isShowingFullInfo = false

    private var usernameText: String? {
        guard let username = item.username?.trimmingCharacters(in: .whitespacesAndNewlines),
              username.isEmpty == false
        else {
            return nil
        }
        return username.hasPrefix("@") ? username : "@\(username)"
    }

    private var titleText: String? {
        if let title = item.title?.trimmingCharacters(in: .whitespacesAndNewlines), title.isEmpty == false {
            return title
        }
        if let titleOverride, titleOverride.isEmpty == false {
            return titleOverride
        }
        return nil
    }

    private var descriptionText: String? {
        guard let description = item.description?.trimmingCharacters(in: .whitespacesAndNewlines),
              description.isEmpty == false
        else {
            return nil
        }
        return description
    }

    private var hasCompactCaption: Bool {
        usernameText != nil || titleText != nil
    }

    private var hasFullInfo: Bool {
        usernameText != nil || titleText != nil || descriptionText != nil
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            compactSurface
                .opacity(isShowingFullInfo ? 0 : 1)
                .allowsHitTesting(!isShowingFullInfo)

            fullInfoSurface
                .opacity(isShowingFullInfo ? 1 : 0)
                .allowsHitTesting(isShowingFullInfo)
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.03, blue: 0.05),
                    Color(red: 0.03, green: 0.03, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .animation(.easeInOut(duration: 0.2), value: isShowingFullInfo)
    }

    private var compactSurface: some View {
        VStack(alignment: .leading, spacing: 11) {
            actionRow

            if hasCompactCaption {
                compactCaptionView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var fullInfoSurface: some View {
        if hasFullInfo {
            HStack(alignment: .top, spacing: 12) {
                MAMetadataAvatarView(avatarURL: item.avatarURL)

                VStack(alignment: .leading, spacing: 8) {
                    if let usernameText {
                        Text(usernameText)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    if let titleText {
                        Text(titleText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let descriptionText {
                        Text(descriptionText)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowingFullInfo = false
                }
            }
        } else {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var actionRow: some View {
        HStack(alignment: .center, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                MAMetadataActionButton(
                    kind: .like(count: item.likeCount),
                    action: onLikeTap
                )
                MAMetadataActionButton(
                    kind: .iconOnly(symbolName: "square.and.arrow.up"),
                    action: onShareTap
                )
                MAMetadataActionButton(
                    kind: .iconOnly(symbolName: "ellipsis"),
                    action: onMoreTap
                )
            }

            Spacer(minLength: 8)

            MAMetadataRemixButton(
                count: item.remixCount,
                action: onRemixTap
            )
            .layoutPriority(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var compactCaptionView: some View {
        compactCaptionText
            .lineLimit(1)
            .truncationMode(.tail)
            .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                guard hasFullInfo else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowingFullInfo = true
                }
            }
    }

    private var compactCaptionText: Text {
        Text([usernameText, titleText].compactMap { $0 }.joined(separator: " "))
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
    }
}

private struct MAMetadataActionButton: View {
    enum MAKind {
        case like(count: Int?)
        case iconOnly(symbolName: String)
    }

    let kind: MAKind
    let action: (() -> Void)?

    var body: some View {
        Button(action: { action?() }) {
            Group {
                switch kind {
                case let .like(count):
                    HStack(spacing: 8) {
                        icon(symbolName: "heart")
                        Text(formattedCount(count))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.96))
                    }
                    .padding(.horizontal, 12)
                    .frame(minWidth: 80, minHeight: 42, alignment: .center)
                    .background(actionBackground)
                    .overlay(actionCapsuleStroke)
                    .clipShape(Capsule())

                case let .iconOnly(symbolName):
                    icon(symbolName: symbolName)
                        .frame(width: 42, height: 42)
                        .background(actionBackground)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1.15)
                        )
                        .clipShape(Circle())
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var actionBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.07, green: 0.09, blue: 0.15).opacity(0.98),
                Color(red: 0.05, green: 0.07, blue: 0.12).opacity(0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var actionCapsuleStroke: some View {
        Capsule()
            .stroke(Color.white.opacity(0.12), lineWidth: 1.15)
    }

    private func icon(symbolName: String) -> some View {
        Image(systemName: symbolName)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
            .foregroundStyle(.white.opacity(0.94))
    }

    private func formattedCount(_ count: Int?) -> String {
        guard let count else { return "0" }
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000).replacingOccurrences(of: ".0", with: "")
        }
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000).replacingOccurrences(of: ".0", with: "")
        }
        return "\(count)"
    }
}

private struct MAMetadataRemixButton: View {
    let count: Int?
    let action: (() -> Void)?

    var body: some View {
        Button(action: { action?() }) {
            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.79, green: 0.29, blue: 1),
                                Color(red: 0.33, green: 0.95, blue: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .blur(radius: 14)
                    .opacity(0.42)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)

                HStack(spacing: 0) {
                    Image(systemName: "shuffle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(.black.opacity(0.8))
                        .padding(.trailing, 8)

                    Text("REMIX")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.black.opacity(0.82))
                        .lineLimit(1)
                        .padding(.trailing, 8)

                    Text(formattedCount(count))
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.black.opacity(0.82))
                        .lineLimit(1)
                }
                .padding(.horizontal, 18)
                .frame(minWidth: 148, minHeight: 50, alignment: .center)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.79, green: 0.29, blue: 1),
                            Color(red: 0.33, green: 0.95, blue: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
                .clipShape(Capsule())
                .shadow(color: Color(red: 0.49, green: 0.25, blue: 1).opacity(0.38), radius: 20, y: 7)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
    }

    private func formattedCount(_ count: Int?) -> String {
        guard let count else { return "0" }
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000).replacingOccurrences(of: ".0", with: "")
        }
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000).replacingOccurrences(of: ".0", with: "")
        }
        return "\(count)"
    }
}

private struct MAMetadataAvatarView: View {
    let avatarURL: URL?

    @State private var loadedImage: UIImage?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.12))

            if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(4)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
        .task(id: avatarURL) {
            await loadAvatarIfNeeded()
        }
    }

    private func loadAvatarIfNeeded() async {
        guard let avatarURL else {
            loadedImage = nil
            return
        }

        if let cachedImage = normalFooterAvatarImageCache.object(forKey: avatarURL as NSURL) {
            loadedImage = cachedImage
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: avatarURL)
            guard let image = UIImage(data: data) else { return }
            normalFooterAvatarImageCache.setObject(image, forKey: avatarURL as NSURL)
            loadedImage = image
        } catch {
            loadedImage = nil
        }
    }
}

final class MAMetadataFooterHostingView: UIView {
    private var hostingController: UIHostingController<MAMetadataFooter>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        isOpaque = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        item: MAPlayableGame,
        titleOverride: String?,
        onLikeTap: (() -> Void)? = nil,
        onShareTap: (() -> Void)? = nil,
        onMoreTap: (() -> Void)? = nil,
        onRemixTap: (() -> Void)? = nil
    ) {
        let rootView = MAMetadataFooter(
            item: item,
            titleOverride: titleOverride,
            onLikeTap: onLikeTap,
            onShareTap: onShareTap,
            onMoreTap: onMoreTap,
            onRemixTap: onRemixTap
        )

        if let hostingController {
            hostingController.rootView = rootView
            hostingController.view.invalidateIntrinsicContentSize()
            return
        }

        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        self.hostingController = hostingController
    }
}
