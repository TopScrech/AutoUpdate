import Foundation
import Testing
@testable import AutoUpdate

@Test
func downloadRequestIncludesAuthorizationForPrivateAssets() throws {
    let provider = GitHubReleaseProvider(token: "ghp_test_token")
    let request = provider.downloadRequest(for: try makeAsset())
    
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer ghp_test_token")
    #expect(request.value(forHTTPHeaderField: "User-Agent") == "AutoUpdate")
}

@Test
func downloadRequestOmitsAuthorizationWhenTokenIsMissing() throws {
    let provider = GitHubReleaseProvider()
    let request = provider.downloadRequest(for: try makeAsset())
    
    #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    #expect(request.value(forHTTPHeaderField: "User-Agent") == "AutoUpdate")
}

private func makeAsset() throws -> Release.Asset {
    let json = """
    {
      "name": "fancontrol-v0.1.1.zip",
      "browser_download_url": "https://github.com/TopScrech/FanControl/releases/download/v0.1.1/fancontrol-v0.1.1.zip",
      "content_type": "application/zip"
    }
    """
    
    return try JSONDecoder().decode(Release.Asset.self, from: Data(json.utf8))
}
