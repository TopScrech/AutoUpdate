import Foundation

enum GitHubProxyURL {
    static func releasesURL(
        owner: String,
        repository: String,
        proxyURL: URL?
    ) -> URL {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repository)/releases")!
        return resolve(url, proxyURL: proxyURL)
    }
    
    static func resolve(_ url: URL, proxyURL: URL?) -> URL {
        guard let proxyURL else {
            return url
        }
        
        let prefix = proxyURL.absoluteString.hasSuffix("/")
        ? proxyURL.absoluteString
        : "\(proxyURL.absoluteString)/"
        
        return URL(string: "\(prefix)\(url.absoluteString)") ?? url
    }
}
