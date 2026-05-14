import Foundation

public struct AppStoreUpdateConfiguration: Equatable, Sendable {
    public let appID: Int
    public let countryCode: String?
    
    public var resolvedAppStoreURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(appID)")
    }
    
    public init(appID: Int, countryCode: String? = nil) {
        self.appID = appID
        self.countryCode = countryCode
    }
}
