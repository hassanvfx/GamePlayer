import UIKit

final class MAAvatarImageLoader {
    static let shared = MAAvatarImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let maximumImageBytes = 2_000_000

    @discardableResult
    func load(from url: URL, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        guard url.scheme?.lowercased() == "https" else {
            completion(nil)
            return nil
        }
        if let image = cache.object(forKey: url as NSURL) {
            completion(image)
            return nil
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, _ in
            let isImage = response?.mimeType?.lowercased().hasPrefix("image/") == true
            let image = isImage && (data?.count ?? 0) <= (self?.maximumImageBytes ?? 0)
                ? data.flatMap(UIImage.init(data:))
                : nil
            if let image {
                self?.cache.setObject(image, forKey: url as NSURL)
            }
            DispatchQueue.main.async { completion(image) }
        }
        task.resume()
        return task
    }
}
