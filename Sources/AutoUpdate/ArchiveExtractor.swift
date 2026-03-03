import Foundation

enum ArchiveExtractor {
    static func extractArchive(
        at archiveURL: URL,
        type: ArchiveType,
        into directoryURL: URL
    ) async throws -> URL {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        let output: ProcessOutput
        switch type {
        case .zip:
            output = try await ProcessExecutor.run(
                "/usr/bin/unzip",
                arguments: ["-q", archiveURL.path, "-d", directoryURL.path]
            )
            
        case .tar:
            output = try await ProcessExecutor.run(
                "/usr/bin/tar",
                arguments: ["-xf", archiveURL.path, "-C", directoryURL.path]
            )
        }
        
        guard output.terminationStatus == 0 else {
            throw AppUpdaterError.extractionFailed
        }
        
        guard let appURL = findAppBundle(in: directoryURL) else {
            throw AppUpdaterError.noDownloadedApplicationBundle
        }
        return appURL
    }
    
    private static func findAppBundle(in rootURL: URL) -> URL? {
        let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        while let element = enumerator?.nextObject() as? URL {
            guard element.pathExtension.lowercased() == "app" else { continue }
            let isDirectory = try? element.resourceValues(forKeys: [.isDirectoryKey]).isDirectory
            
            if isDirectory == true {
                return element
            }
        }
        
        return nil
    }
}
