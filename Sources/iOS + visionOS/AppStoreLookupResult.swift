#if os(iOS) || os(visionOS)

import Foundation

struct AppStoreLookupResult: Decodable, Sendable {
    let version: String
    let trackViewURL: URL?
    
    enum CodingKeys: String, CodingKey {
        case version, trackViewURL = "trackViewUrl"
    }
}

#endif
