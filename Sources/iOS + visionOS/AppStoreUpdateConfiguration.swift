#if os(iOS) || os(visionOS)

import Foundation

public struct AppStoreUpdateConfiguration: Equatable, Sendable {
    public let appID: Int
    public let countryCode: String?
    public let appStoreURL: URL?

    public init(appID: Int, countryCode: String? = nil, appStoreURL: URL? = nil) {
        self.appID = appID
        self.countryCode = countryCode
        self.appStoreURL = appStoreURL
    }
}

#endif
