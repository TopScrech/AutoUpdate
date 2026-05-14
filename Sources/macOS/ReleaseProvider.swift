#if os(macOS)

import Foundation

public protocol ReleaseProvider: Sendable {
    func releases(owner: String, repository: String) async throws -> [Release]
}

#endif
