#if os(iOS) || os(visionOS)

struct AppStoreLookupResponse: Decodable, Sendable {
    let results: [AppStoreLookupResult]
}

#endif
