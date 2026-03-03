import SwiftUI

public actor AppUpdater {
    public enum CodeSigningValidation: Sendable {
        case required, skipped
    }
    
    public struct Configuration {
        public var owner: String
        public var repository: String
        public var releasePrefix: String
        public var allowPrereleases: Bool
        public var codeSigningValidation: CodeSigningValidation
        public var session: URLSession
        
        public init(
            owner: String,
            repository: String,
            releasePrefix: String? = nil,
            allowPrereleases: Bool = false,
            codeSigningValidation: CodeSigningValidation = .required,
            session: URLSession = .shared
        ) {
            self.owner = owner
            self.repository = repository
            self.releasePrefix = releasePrefix ?? repository
            self.allowPrereleases = allowPrereleases
            self.codeSigningValidation = codeSigningValidation
            self.session = session
        }
    }
    
    private let releaseProvider: any ReleaseProvider
    private var configuration: Configuration
    private var isChecking = false
    private var scheduler: NSBackgroundActivityScheduler?
    
    public init(configuration: Configuration, releaseProvider: any ReleaseProvider) {
        self.configuration = configuration
        self.releaseProvider = releaseProvider
    }
    
    public init(
        owner: String,
        repository: String,
        releasePrefix: String? = nil,
        allowPrereleases: Bool = false,
        codeSigningValidation: CodeSigningValidation = .required,
        session: URLSession = .shared,
        releaseProvider: (any ReleaseProvider)? = nil
    ) {
        let configuration = Configuration(
            owner: owner,
            repository: repository,
            releasePrefix: releasePrefix,
            allowPrereleases: allowPrereleases,
            codeSigningValidation: codeSigningValidation,
            session: session
        )
        self.configuration = configuration
        self.releaseProvider = releaseProvider ?? GitHubReleaseProvider(session: session)
    }
    
    public func setAllowPrereleases(_ allowPrereleases: Bool) {
        configuration.allowPrereleases = allowPrereleases
    }
    
    public func setCodeSigningValidation(_ validation: CodeSigningValidation) {
        configuration.codeSigningValidation = validation
    }
    
    public func startAutomaticChecks(
        identifier: String? = nil,
        every interval: TimeInterval = 24 * 60 * 60,
        installAfterPreparation: Bool = false
    ) {
        stopAutomaticChecks()
        
        let resolvedIdentifier = identifier ?? "AutoUpdate.\(Bundle.main.bundleIdentifier ?? UUID().uuidString)"
        let scheduler = NSBackgroundActivityScheduler(identifier: resolvedIdentifier)
        scheduler.repeats = true
        scheduler.interval = interval
        
        scheduler.schedule { [weak self] completion in
            guard let self else {
                completion(.finished)
                return
            }
            
            Task {
                let shouldDefer = await self.shouldDeferAutomaticCheck()
                guard !shouldDefer else {
                    completion(.deferred)
                    return
                }
                
                do {
                    if installAfterPreparation {
                        if case .prepared(let preparedUpdate) = try await self.prepareUpdateIfAvailable() {
                            completion(.finished)
                            try await self.installAndRelaunch(preparedUpdate)
                            return
                        }
                    } else {
                        _ = try await self.prepareUpdateIfAvailable()
                    }
                    
                    completion(.finished)
                    
                } catch AppUpdaterError.updateCheckAlreadyRunning {
                    completion(.deferred)
                    
                } catch {
                    completion(.finished)
                }
            }
        }
        
        self.scheduler = scheduler
    }
    
    public func stopAutomaticChecks() {
        scheduler?.invalidate()
        scheduler = nil
    }
    
    public func checkForUpdates() async throws -> UpdateCheckResult {
        try await withCheckLock {
            let currentVersion = try Self.currentAppVersion()
            
            let releases = try await releaseProvider.releases(
                owner: configuration.owner,
                repository: configuration.repository
            )
            
            guard let update = newestCandidate(releases: releases, currentVersion: currentVersion) else {
                return .upToDate
            }
            
            return .updateAvailable(update)
        }
    }
    
    @discardableResult
    public func check() async throws -> UpdatePreparationResult {
        try await prepareUpdateIfAvailable()
    }
    
    public func prepareUpdateIfAvailable() async throws -> UpdatePreparationResult {
        try await withCheckLock {
            let currentVersion = try Self.currentAppVersion()
            
            let releases = try await releaseProvider.releases(
                owner: configuration.owner,
                repository: configuration.repository
            )
            
            guard let candidate = newestCandidate(releases: releases, currentVersion: currentVersion) else {
                return .upToDate
            }
            
            let preparedUpdate = try await prepare(candidate)
            return .prepared(preparedUpdate)
        }
    }
    
    public func installAndRelaunch(_ preparedUpdate: PreparedUpdate) async throws {
        guard let downloadedBundle = Bundle(url: preparedUpdate.bundleURL) else {
            throw AppUpdaterError.installationFailed
        }
        
        guard let executableRelativePath = downloadedBundle.executableRelativePath else {
            throw AppUpdaterError.installationFailed
        }
        
        let installedBundleURL = Bundle.main.bundleURL
        let relaunchedExecutableURL = installedBundleURL.appendingPathComponent(executableRelativePath)
        
        do {
            try FileManager.default.removeItem(at: installedBundleURL)
            try FileManager.default.moveItem(at: preparedUpdate.bundleURL, to: installedBundleURL)
            
            let process = Process()
            process.executableURL = relaunchedExecutableURL
            try process.run()
            
            try? FileManager.default.removeItem(at: preparedUpdate.temporaryDirectoryURL)
        } catch {
            throw AppUpdaterError.installationFailed
        }
        
        await MainActor.run {
            NSApp.terminate(nil)
        }
    }
    
    public func discardPreparedUpdate(_ preparedUpdate: PreparedUpdate) {
        try? FileManager.default.removeItem(at: preparedUpdate.temporaryDirectoryURL)
    }
    
    private func withCheckLock<T>(_ operation: () async throws -> T) async throws -> T {
        guard !isChecking else {
            throw AppUpdaterError.updateCheckAlreadyRunning
        }
        
        isChecking = true
        defer { isChecking = false }
        
        return try await operation()
    }
    
    private func shouldDeferAutomaticCheck() -> Bool {
        scheduler?.shouldDefer ?? false
    }
    
    private static func currentAppVersion() throws -> SemanticVersion {
        guard Bundle.main.executableURL != nil else {
            throw AppUpdaterError.missingBundleExecutable
        }
        
        let info = Bundle.main.infoDictionary
        
        guard let rawVersion = (
            info?["CFBundleShortVersionString"] as? String ??
            info?["CFBundleVersion"] as? String
        ) else {
            throw AppUpdaterError.missingBundleVersion
        }
        
        do {
            return try SemanticVersion(parsing: rawVersion)
        } catch {
            throw AppUpdaterError.invalidVersionString(rawVersion)
        }
    }
    
    private func newestCandidate(
        releases: [Release],
        currentVersion: SemanticVersion
    ) -> UpdateCandidate? {
        let available = releases
            .compactMap { release -> (Release, SemanticVersion)? in
                guard let version = release.semanticVersion else { return nil }
                return (release, version)
            }
            .filter { release, version in
                version > currentVersion && (configuration.allowPrereleases || !release.isPrerelease)
            }
            .sorted { lhs, rhs in
                lhs.1 > rhs.1
            }
        
        for (release, _) in available {
            if let asset = viableAsset(for: release) {
                return UpdateCandidate(release: release, asset: asset)
            }
        }
        
        return nil
    }
    
    private func viableAsset(for release: Release) -> Release.Asset? {
        guard let version = release.semanticVersion else { return nil }
        
        let expectedName = "\(configuration.releasePrefix.lowercased())-\(version.description.lowercased())"
        let expectedNameWithV = "\(configuration.releasePrefix.lowercased())-v\(version.description.lowercased())"
        
        return release.assets.first { asset in
            guard let archiveType = asset.archiveType else { return false }
            
            let name = asset.name.lowercased()
            let nameWithoutExtension = (name as NSString).deletingPathExtension
            
            switch archiveType {
            case .zip:
                return nameWithoutExtension == expectedName || nameWithoutExtension == expectedNameWithV
                
            case .tar:
                return nameWithoutExtension == expectedName
                || nameWithoutExtension == expectedNameWithV
                || nameWithoutExtension == "\(expectedName).tar"
                || nameWithoutExtension == "\(expectedNameWithV).tar"
            }
        }
    }
    
    private func prepare(_ candidate: UpdateCandidate) async throws -> PreparedUpdate {
        let temporaryDirectory = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: Bundle.main.bundleURL,
            create: true
        )
        
        let archiveURL = temporaryDirectory.appendingPathComponent("update.archive")
        _ = try await download(asset: candidate.asset, to: archiveURL)
        
        guard let archiveType = candidate.asset.archiveType else {
            throw AppUpdaterError.unsupportedArchive(
                contentType: candidate.asset.contentType,
                fileName: candidate.asset.name
            )
        }
        
        let extractedDirectory = temporaryDirectory.appendingPathComponent("extracted", isDirectory: true)
        let downloadedBundleURL = try await ArchiveExtractor.extractArchive(
            at: archiveURL,
            type: archiveType,
            into: extractedDirectory
        )
        
        guard let downloadedBundle = Bundle(url: downloadedBundleURL) else {
            throw AppUpdaterError.noDownloadedApplicationBundle
        }
        
        try await validateCodeSigning(for: downloadedBundle)
        
        return PreparedUpdate(
            release: candidate.release,
            asset: candidate.asset,
            bundleURL: downloadedBundleURL,
            temporaryDirectoryURL: temporaryDirectory
        )
    }
    
    private func download(asset: Release.Asset, to destination: URL) async throws -> URL {
        let (downloadedURL, response) = try await configuration.session.download(from: asset.downloadURL)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        
        try FileManager.default.moveItem(at: downloadedURL, to: destination)
        return destination
    }
    
    private func validateCodeSigning(for downloadedBundle: Bundle) async throws {
        guard configuration.codeSigningValidation == .required else {
            return
        }
        
        let installedIdentity = try await Bundle.main.codeSigningIdentity()
        let downloadedIdentity = try await downloadedBundle.codeSigningIdentity()
        
        guard installedIdentity == downloadedIdentity else {
            throw AppUpdaterError.codeSigningIdentityMismatch(
                expected: installedIdentity,
                actual: downloadedIdentity
            )
        }
    }
}
