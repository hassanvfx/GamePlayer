import Foundation
@testable import GamePlayer
import Testing
import WebKit

struct MAArcadeCatalogTests {
    @Test func permitsSecureNavigation() {
        #expect(MAWebNavigationPolicy.decision(for: URL(string: "https://games.example.com/play")) == .allow)
    }

    @Test func rejectsUnsafeNavigation() {
        for value in [
            "http://games.example.com",
            "file:///tmp/game.html",
            "javascript:alert(1)",
            "data:text/html,test"
        ] {
            #expect(MAWebNavigationPolicy.decision(for: URL(string: value)) == .cancel)
        }
    }

    @Test @MainActor func loadsOnlySecureCatalogGames() {
        #expect(!MAArcadeCatalog.all.isEmpty)
        #expect(MAArcadeCatalog.all.allSatisfy { $0.webURL.scheme?.lowercased() == "https" && $0.webURL.host != nil })
    }
}
