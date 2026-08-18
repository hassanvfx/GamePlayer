import Foundation
import WebKit

enum MAWebNavigationPolicy {
    static func decision(for url: URL?) -> WKNavigationActionPolicy {
        guard let url, url.scheme?.lowercased() == "https", url.host != nil else {
            return .cancel
        }
        return .allow
    }

    static func decision(for response: URLResponse?) -> WKNavigationResponsePolicy {
        guard let url = response?.url, decision(for: url) == .allow else {
            return .cancel
        }
        return .allow
    }
}
