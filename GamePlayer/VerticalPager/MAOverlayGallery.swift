import SwiftUI

struct MAOverlayGallery: View {
    let item: MAPlayableGame
    var showOverlay: Bool = true
    var showElapsedIndicator: Bool = true
    var elapsedProgress: CGFloat = 0.65
    var surfaceTitle: String? = nil
    var surfaceSubtitle: String? = nil

    var body: some View {
        MAOverlaySurfaceCard(
            item: item,
            showOverlay: showOverlay,
            showElapsedIndicator: showElapsedIndicator,
            elapsedProgress: elapsedProgress,
            surfaceTitle: surfaceTitle,
            surfaceSubtitle: surfaceSubtitle
        )
    }
}

private struct MAOverlaySurfaceCard: View {
    let item: MAPlayableGame
    let showOverlay: Bool
    let showElapsedIndicator: Bool
    let elapsedProgress: CGFloat
    let surfaceTitle: String?
    let surfaceSubtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if surfaceTitle != nil || surfaceSubtitle != nil {
                VStack(alignment: .leading, spacing: 4) {
                    if let surfaceTitle {
                        Text(surfaceTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    if let surfaceSubtitle {
                        Text(surfaceSubtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 2)
            }

            ZStack(alignment: .bottom) {
                MAOverlayMockContent()
                MAOverlayFooterSurface(
                    item: item,
                    showOverlay: showOverlay,
                    showElapsedIndicator: showElapsedIndicator,
                    elapsedProgress: elapsedProgress
                )
            }
            .frame(height: 520)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(red: 0.05, green: 0.06, blue: 0.08))
            )
        }
    }
}

private struct MAOverlayFooterSurface: View {
    let item: MAPlayableGame
    let showOverlay: Bool
    let showElapsedIndicator: Bool
    let elapsedProgress: CGFloat

    private let footerHeight: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topLeading) {
            footerBase

            if showOverlay {
                overlaySurface
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(height: footerHeight)
    }

    private var footerBase: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.94))

            if showElapsedIndicator && !showOverlay {
                VStack(spacing: 0) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.12))
                            Rectangle()
                                .fill(Color.white.opacity(0.92))
                                .frame(width: geometry.size.width * max(0, min(1, elapsedProgress)))
                        }
                    }
                    .frame(height: 1)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
            }

            HStack(alignment: .top, spacing: 12) {
                if item.avatarURL != nil {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundStyle(.white.opacity(0.88))
                        )
                        .frame(width: 34, height: 34)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let username = nonEmpty(item.username) {
                        Text(username)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    if let title = nonEmpty(item.title) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }

                    if let description = nonEmpty(item.description) {
                        Text(description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(3)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
        }
    }

    private var overlaySurface: some View {
        MAMetadataFooter(item: item)
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value, value.isEmpty == false else { return nil }
        return value
    }
}

private struct MAOverlayMockContent: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.11, blue: 0.16),
                    Color(red: 0.03, green: 0.03, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text("Preview Surface")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(.white.opacity(0.08))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(24)
        }
    }
}

private struct MAOverlayPreviewCatalog: View {
    private let richItem = MAPlayableGame(
        webURL: URL(string: "https://example.com")!,
        title: "MemeArcade",
        description: "Original footer visible underneath, with the solid overlay covering it for composition preview.",
        username: "@preview_creator",
        avatarURL: URL(string: "https://example.com/avatar.png"),
        remixCount: 12,
        likeCount: 4216,
        shareCount: 98,
        chatCount: 15,
        isLive: true
    )

    private let compactItem = MAPlayableGame(
        webURL: URL(string: "https://example.com")!,
        title: "Compact metadata surface",
        description: "No avatar and a simpler metadata footprint to validate edge-case layout.",
        username: "@compact",
        remixCount: 1,
        likeCount: 8,
        shareCount: 2,
        chatCount: 3,
        isLive: false
    )

    private let titleOnlyItem = MAPlayableGame(
        webURL: URL(string: "https://example.com")!,
        title: "Title-only fallback content for extraction previews",
        remixCount: 104,
        likeCount: 2400,
        shareCount: 18,
        chatCount: 0,
        isLive: false
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("MA Surface Catalog")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)

                Text(
                    "Design-system style preview of the reusable footer and action-overlay states inside the MA module."
                )
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

                MAOverlayGallery(
                    item: richItem,
                    showOverlay: false,
                    showElapsedIndicator: false,
                    elapsedProgress: 0,
                    surfaceTitle: "Footer / Base",
                    surfaceSubtitle: "Default footer metadata without countdown or overlay."
                )

                MAOverlayGallery(
                    item: richItem,
                    showOverlay: false,
                    showElapsedIndicator: true,
                    elapsedProgress: 0.68,
                    surfaceTitle: "Footer / Idle Countdown",
                    surfaceSubtitle: "Hairline progress state before the action bar appears."
                )

                MAOverlayGallery(
                    item: richItem,
                    showOverlay: true,
                    showElapsedIndicator: false,
                    elapsedProgress: 1,
                    surfaceTitle: "Overlay / Live Chat",
                    surfaceSubtitle: "Primary solid overlay with grouped actions and live chat emphasis."
                )

                MAOverlayGallery(
                    item: compactItem,
                    showOverlay: true,
                    showElapsedIndicator: false,
                    elapsedProgress: 1,
                    surfaceTitle: "Overlay / Compact Metadata",
                    surfaceSubtitle: "No-avatar variant for denser item payloads."
                )

                MAOverlayGallery(
                    item: titleOnlyItem,
                    showOverlay: false,
                    showElapsedIndicator: false,
                    elapsedProgress: 0,
                    surfaceTitle: "Footer / Minimal Content",
                    surfaceSubtitle: "Fallback behavior when only title-level content is provided."
                )
            }
            .padding(24)
        }
        .background(Color.black)
    }
}

#Preview("MA Surface Catalog") {
    MAOverlayPreviewCatalog()
}
