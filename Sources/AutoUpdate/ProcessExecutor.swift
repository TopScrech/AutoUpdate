import Foundation

struct ProcessOutput {
    let terminationStatus: Int32
    let standardOutput: Data
    let standardError: Data
}

enum ProcessExecutor {
    static func run(
        _ executable: String,
        arguments: [String],
        currentDirectoryURL: URL? = nil
    ) async throws -> ProcessOutput {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.currentDirectoryURL = currentDirectoryURL
            
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            
            try process.run()
            process.waitUntilExit()
            
            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            
            return ProcessOutput(
                terminationStatus: process.terminationStatus,
                standardOutput: stdoutData,
                standardError: stderrData
            )
        }.value
    }
}
