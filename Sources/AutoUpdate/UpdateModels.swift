import Foundation

public struct UpdateCandidate: Hashable, Sendable {
    public let release: Release
    public let asset: Release.Asset
    
    public init(release: Release, asset: Release.Asset) {
        self.release = release
        self.asset = asset
    }
}

public struct PreparedUpdate: Hashable, Sendable {
    public let release: Release
    public let asset: Release.Asset
    public let bundleURL: URL
    public let temporaryDirectoryURL: URL
    
    public init(
        release: Release,
        asset: Release.Asset,
        bundleURL: URL,
        temporaryDirectoryURL: URL
    ) {
        self.release = release
        self.asset = asset
        self.bundleURL = bundleURL
        self.temporaryDirectoryURL = temporaryDirectoryURL
    }
}

public enum UpdateCheckResult: Equatable, Sendable {
    case upToDate, updateAvailable(UpdateCandidate)
}

public enum UpdatePreparationResult: Equatable, Sendable {
    case upToDate, prepared(PreparedUpdate)
}
