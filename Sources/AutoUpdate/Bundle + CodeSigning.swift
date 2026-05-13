import Foundation

extension Bundle {
    var executableRelativePath: String? {
        guard let executableURL else { return nil }
        
        let bundlePath = bundleURL.path
        let executablePath = executableURL.path
        guard executablePath.hasPrefix(bundlePath) else { return nil }
        
        let relativePath = executablePath.dropFirst(bundlePath.count)
        
        if relativePath.first == "/" {
            return String(relativePath.dropFirst())
        }
        
        return String(relativePath)
    }
    
    func codeSigningIdentity() async throws -> String {
        let output = try await ProcessExecutor.run(
            "/usr/bin/codesign",
            arguments: ["-dvvv", bundleURL.path]
        )
        
        guard output.terminationStatus == 0 else {
            throw AppUpdaterError.codeSigningIdentityUnavailable(bundleURL)
        }
        
        let description = String(decoding: output.standardError, as: UTF8.self)
        
        guard let authorityLine = description
            .split(separator: "\n")
            .first(where: { $0.hasPrefix("Authority=") })
        else {
            throw AppUpdaterError.codeSigningIdentityUnavailable(bundleURL)
        }
        
        return String(authorityLine.dropFirst("Authority=".count))
    }
    
    func validateCodeSignature() async throws {
        let output = try await ProcessExecutor.run(
            "/usr/bin/codesign",
            arguments: ["--verify", "--deep", "--strict", "--verbose=2", bundleURL.path]
        )
        
        guard output.terminationStatus == 0 else {
            let details = String(decoding: output.standardError, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw AppUpdaterError.codeSigningValidationFailed(
                bundleURL,
                details: details.isEmpty ? nil : details
            )
        }
    }
}
