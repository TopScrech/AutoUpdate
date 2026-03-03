import Foundation

public protocol ReleaseProvider: Sendable {
    func releases(owner: String, repository: String) async throws -> [Release]
    func downloadRequest(for asset: Release.Asset) -> URLRequest
}

public extension ReleaseProvider {
    func downloadRequest(for asset: Release.Asset) -> URLRequest {
        URLRequest(url: asset.downloadURL)
    }
}
