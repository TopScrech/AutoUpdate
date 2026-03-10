import Foundation

public enum AppUpdaterError: Error, LocalizedError, Sendable {
    case missingBundleExecutable,
         missingBundleVersion,
         invalidVersionString(String),
         updateCheckAlreadyRunning,
         noDownloadedApplicationBundle,
         codeSigningIdentityUnavailable(URL),
         codeSigningValidationFailed(URL, details: String?),
         codeSigningIdentityMismatch(expected: String, actual: String),
         unsupportedArchive(contentType: String, fileName: String),
         extractionFailed,
         installationFailed
    
    public var errorDescription: String? {
        switch self {
        case .missingBundleExecutable:
            "Main bundle executable URL is unavailable"
            
        case .missingBundleVersion:
            "Main bundle does not contain a version string"
            
        case .invalidVersionString(let version):
            "Unable to parse semantic version: \(version)"
            
        case .updateCheckAlreadyRunning:
            "An update check is already running"
            
        case .noDownloadedApplicationBundle:
            "No valid .app bundle was found in the downloaded archive"
            
        case .codeSigningIdentityUnavailable(let bundleURL):
            "Code signing identity is unavailable for bundle: \(bundleURL.path)"
            
        case .codeSigningValidationFailed(let bundleURL, let details):
            if let details, !details.isEmpty {
                "Code signing validation failed for bundle: \(bundleURL.path)\n\(details)"
            } else {
                "Code signing validation failed for bundle: \(bundleURL.path)"
            }
            
        case .codeSigningIdentityMismatch(let expected, let actual):
            "Code signing identity mismatch expected \(expected) but got \(actual)"
            
        case .unsupportedArchive(let contentType, let fileName):
            "Unsupported archive \(fileName) with content type \(contentType)"
            
        case .extractionFailed:
            "Failed to extract the downloaded archive"
            
        case .installationFailed:
            "Failed to install and relaunch the updated app"
        }
    }
}
