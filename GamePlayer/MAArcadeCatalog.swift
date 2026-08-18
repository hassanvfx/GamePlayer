import Foundation

@MainActor
enum MAArcadeCatalog {
    static let all = loadCatalog()

    static let preview: [MAPlayableGame] = [
        MAPlayableGame(
            webURL: URL(string: "https://example.com")!,
            title: "Example Preview",
            description: "Preview item for SwiftUI canvas rendering.",
            username: "@preview",
            avatarURL: nil,
            remixCount: 2,
            likeCount: 3,
            shareCount: 2,
            chatCount: 15
        )
    ]

    private static func loadCatalog(bundle: Bundle = .main) -> [MAPlayableGame] {
        guard
            let catalogURL = bundle.url(forResource: "GameCatalog", withExtension: "json"),
            let catalogData = try? Data(contentsOf: catalogURL),
            let records = try? JSONDecoder().decode([MAArcadeCatalogRecord].self, from: catalogData)
        else {
            assertionFailure("GameCatalog.json is missing or invalid.")
            return []
        }

        return records.compactMap(MAPlayableGame.init(record:))
    }
}

private struct MAArcadeCatalogRecord: Decodable {
    let url: String
    let title: String?
    let description: String?
    let username: String?
    let avatarURL: String?
    let remixCount: Int?
    let likeCount: Int?
    let shareCount: Int?
    let chatCount: Int?
}

private extension MAPlayableGame {
    init?(record: MAArcadeCatalogRecord) {
        guard
            let webURL = URL(string: record.url),
            webURL.scheme?.lowercased() == "https",
            webURL.host != nil
        else {
            return nil
        }

        self.init(
            webURL: webURL,
            title: record.title,
            description: record.description,
            username: record.username,
            avatarURL: record.avatarURL
                .flatMap(URL.init(string:))
                .flatMap { $0.scheme?.lowercased() == "https" && $0.host != nil ? $0 : nil },
            remixCount: record.remixCount,
            likeCount: record.likeCount,
            shareCount: record.shareCount,
            chatCount: record.chatCount
        )
    }
}
