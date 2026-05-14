#if os(iOS) || os(visionOS)

import Foundation

struct AppStoreLookupResult: Decodable, Sendable {
    let version: String
    let trackViewURL: URL?
}

#endif
