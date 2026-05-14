import Foundation

@MainActor
@Observable
public final class AppStoreUpdateChecker {
    public private(set) var latestStatus: AppStoreUpdateStatus?
    public private(set) var isChecking = false
    public var alertUpdate = false
    
    public let configuration: AppStoreUpdateConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    
    public init(configuration: AppStoreUpdateConfiguration, session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.configuration = configuration
        self.session = session
        self.decoder = decoder
    }
    
    public convenience init(appID: Int, countryCode: String? = nil) {
        self.init(configuration: AppStoreUpdateConfiguration(appID: appID, countryCode: countryCode))
    }
    
    public static func isUpdateAvailable(currentVersion: String, appStoreVersion: String) -> Bool {
        let currentParts = versionComponents(from: currentVersion)
        let storeParts = versionComponents(from: appStoreVersion)
        
        for (current, store) in zip(currentParts, storeParts) {
            if current != store {
                return current < store
            }
        }
        
        return currentParts.count < storeParts.count
    }
    
    public func startCheck(after delay: Duration = .seconds(1)) async {
        do {
            try await Task.sleep(for: delay)
        } catch {
            return
        }
        
        await checkForUpdates()
    }
    
    @discardableResult
    public func checkForUpdates(currentVersion: String? = nil) async -> AppStoreUpdateStatus? {
        guard !isChecking else { return latestStatus }
        guard let resolvedCurrentVersion = currentVersion ?? Self.currentBundleVersion else { return nil }
        guard let lookupURL else { return nil }
        
        isChecking = true
        defer { isChecking = false }
        
        do {
            let (data, _) = try await session.data(from: lookupURL)
            let response = try decoder.decode(AppStoreLookupResponse.self, from: data)
            let result = response.results.first
            let appStoreVersion = result?.version
            let updateAvailable = appStoreVersion.map {
                Self.isUpdateAvailable(currentVersion: resolvedCurrentVersion, appStoreVersion: $0)
            } ?? false
            
            let status = AppStoreUpdateStatus(
                currentVersion: resolvedCurrentVersion,
                appStoreVersion: appStoreVersion,
                appStoreURL: result?.trackViewURL ?? configuration.resolvedAppStoreURL,
                updateAvailable: updateAvailable
            )
            
            latestStatus = status
            alertUpdate = status.updateAvailable
            return status
        } catch {
            return nil
        }
    }
    
    private static var currentBundleVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    private var lookupURL: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = "/lookup"
        
        var queryItems = [
            URLQueryItem(name: "id", value: String(configuration.appID))
        ]
        
        if let countryCode = configuration.countryCode {
            queryItems.append(URLQueryItem(name: "country", value: countryCode))
        }
        
        components.queryItems = queryItems
        return components.url
    }
    
    private static func versionComponents(from version: String) -> [Int] {
        let rawParts = version.split(separator: ".")
        var parts = rawParts.map { part in
            let digits = part.prefix { $0.isNumber }
            return Int(digits) ?? 0
        }
        
        while parts.last == 0, parts.count > 1 {
            parts.removeLast()
        }
        
        return parts
    }
}
