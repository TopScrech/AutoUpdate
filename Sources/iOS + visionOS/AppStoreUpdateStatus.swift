import Foundation

public struct AppStoreUpdateStatus: Equatable, Sendable {
    public let currentVersion: String
    public let appStoreVersion: String?
    public let appStoreURL: URL?
    public let updateAvailable: Bool
    
    public init(currentVersion: String, appStoreVersion: String?, appStoreURL: URL?, updateAvailable: Bool) {
        self.currentVersion = currentVersion
        self.appStoreVersion = appStoreVersion
        self.appStoreURL = appStoreURL
        self.updateAvailable = updateAvailable
    }
}
