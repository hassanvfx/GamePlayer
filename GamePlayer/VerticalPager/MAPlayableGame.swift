import Foundation

struct MAPlayableGame: Hashable {
    let webURL: URL
    let title: String?
    let description: String?
    let username: String?
    let avatarURL: URL?
    let remixCount: Int?
    let likeCount: Int?
    let shareCount: Int?
    let chatCount: Int?
    let isLive: Bool

    init(
        webURL: URL,
        title: String? = nil,
        description: String? = nil,
        username: String? = nil,
        avatarURL: URL? = nil,
        remixCount: Int? = nil,
        likeCount: Int? = nil,
        shareCount: Int? = nil,
        chatCount: Int? = nil,
        isLive: Bool = true
    ) {
        self.webURL = webURL
        self.title = title
        self.description = description
        self.username = username
        self.avatarURL = avatarURL
        self.remixCount = remixCount
        self.likeCount = likeCount
        self.shareCount = shareCount
        self.chatCount = chatCount
        self.isLive = isLive
    }
}
