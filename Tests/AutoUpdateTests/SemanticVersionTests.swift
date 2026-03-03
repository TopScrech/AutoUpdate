import Testing
@testable import AutoUpdate

@Test
func parsesTwoOrThreeComponentVersions() throws {
    let twoComponent = try SemanticVersion(parsing: "1.4")
    #expect(twoComponent.major == 1)
    #expect(twoComponent.minor == 4)
    #expect(twoComponent.patch == 0)
    
    let threeComponent = try SemanticVersion(parsing: "2.5.9")
    #expect(threeComponent.major == 2)
    #expect(threeComponent.minor == 5)
    #expect(threeComponent.patch == 9)
}

@Test
func comparesPrereleasesWithSemverRules() throws {
    let alpha = try SemanticVersion(parsing: "1.0.0-alpha.1")
    let beta = try SemanticVersion(parsing: "1.0.0-beta.1")
    let stable = try SemanticVersion(parsing: "1.0.0")
    
    #expect(alpha < beta)
    #expect(beta < stable)
}

@Test
func acceptsVPrefix() throws {
    let version = try SemanticVersion(parsing: "v3.2.1")
    #expect(version.description == "3.2.1")
}
