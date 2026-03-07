import Foundation
import Testing
@testable import AutoUpdate

@Test
func matchesAssetsUsingRawTagNameWithoutPatchComponent() throws {
    let release = try decodeRelease(
        tagName: "v1.2",
        assetNames: ["FanControl-1.2.zip"]
    )
    
    let names = AppUpdater.expectedAssetBaseNames(
        releasePrefix: "FanControl",
        release: release
    )
    
    #expect(names.contains("fancontrol-1.2"))
    #expect(names.contains("fancontrol-v1.2"))
    #expect(names.contains("fancontrol-1.2.0"))
}

private func decodeRelease(tagName: String, assetNames: [String]) throws -> Release {
    let assets = assetNames.map {
        [
            "name": $0,
            "browser_download_url": "https://example.com/\($0)",
            "content_type": "application/zip"
        ]
    }
    let payload: [String: Any] = [
        "tag_name": tagName,
        "prerelease": false,
        "body": "Notes",
        "assets": assets
    ]
    let data = try JSONSerialization.data(withJSONObject: payload)
    return try JSONDecoder().decode(Release.self, from: data)
}
