import Foundation

public struct GitHubReleaseProvider: ReleaseProvider, Sendable {
    private let session: URLSession
    private let token: String?
    private let additionalHeaders: [String: String]
    
    public init(
        session: URLSession = .shared,
        token: String? = nil,
        additionalHeaders: [String: String] = [:]
    ) {
        self.session = session
        self.token = token
        self.additionalHeaders = additionalHeaders
    }
    
    public func releases(owner: String, repository: String) async throws -> [Release] {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repository)/releases")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("AutoUpdate", forHTTPHeaderField: "User-Agent")
        
        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([Release].self, from: data)
    }
}
