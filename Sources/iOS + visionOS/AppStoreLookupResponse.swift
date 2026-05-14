struct AppStoreLookupResponse: Decodable, Sendable {
    let results: [AppStoreLookupResult]
}
