import Foundation

public struct Release: Decodable, Hashable, Sendable {
    public struct Asset: Decodable, Hashable, Sendable {
        public let name: String
        public let downloadURL: URL
        public let contentType: String
        
        enum CodingKeys: String, CodingKey {
            case name,
                 downloadURL = "browser_download_url",
                 contentType = "content_type"
        }
    }
    
    public let tagName: String
    public let isPrerelease: Bool
    public let htmlURL: URL?
    public let body: String
    public let assets: [Asset]
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case isPrerelease = "prerelease"
        case htmlURL = "html_url"
        case body
        case assets
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tagName = try container.decode(String.self, forKey: .tagName)
        isPrerelease = try container.decode(Bool.self, forKey: .isPrerelease)
        htmlURL = try container.decodeIfPresent(URL.self, forKey: .htmlURL)
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        assets = try container.decodeIfPresent([Asset].self, forKey: .assets) ?? []
    }
    
    public var semanticVersion: SemanticVersion? {
        try? SemanticVersion(parsing: tagName)
    }
}

public enum ArchiveType: Sendable {
    case zip, tar
}

extension Release.Asset {
    var archiveType: ArchiveType? {
        let lowerContentType = contentType.lowercased()
        if lowerContentType == "application/zip" {
            return .zip
        }
        
        let tarTypes: Set<String> = [
            "application/x-bzip2",
            "application/x-xz",
            "application/x-gzip",
            "application/gzip",
            "application/x-tar"
        ]
        
        if tarTypes.contains(lowerContentType) {
            return .tar
        }
        
        let lowerName = name.lowercased()
        
        if lowerName.hasSuffix(".zip") {
            return .zip
        }
        
        if lowerName.hasSuffix(".tar")
            || lowerName.hasSuffix(".tar.gz")
            || lowerName.hasSuffix(".tgz")
            || lowerName.hasSuffix(".tar.bz2")
            || lowerName.hasSuffix(".tbz")
            || lowerName.hasSuffix(".tar.xz")
        {
            return .tar
        }
        
        return nil
    }
}
