import Foundation
import Testing
@testable import AutoUpdate

@Test
func leavesURLUntouchedWithoutProxy() {
    let url = URL(string: "https://github.com/owner/repository/releases/download/v1.2.3/app.zip")!
    
    #expect(GitHubProxyURL.resolve(url, proxyURL: nil) == url)
}

@Test
func prefixesReleaseAPIRouteWithProxy() {
    let proxyURL = URL(string: "https://ghproxy.example.com")!
    let url = GitHubProxyURL.releasesURL(
        owner: "owner",
        repository: "repository",
        proxyURL: proxyURL
    )
    
    #expect(
        url.absoluteString
            == "https://ghproxy.example.com/https://api.github.com/repos/owner/repository/releases"
    )
}

@Test
func prefixesAssetDownloadRouteWithProxy() {
    let proxyURL = URL(string: "https://ghproxy.example.com/mirror")!
    let assetURL = URL(string: "https://github.com/owner/repository/releases/download/v1.2.3/app.zip")!
    let proxiedURL = GitHubProxyURL.resolve(assetURL, proxyURL: proxyURL)
    
    #expect(
        proxiedURL.absoluteString
            == "https://ghproxy.example.com/mirror/https://github.com/owner/repository/releases/download/v1.2.3/app.zip"
    )
}
