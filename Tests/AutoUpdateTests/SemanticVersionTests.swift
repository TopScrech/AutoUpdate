import Testing
@testable import AutoUpdate

struct Tests {
    @Test
    func parsesTwoVersionCompinents() throws {
        let twoComponent = try SemanticVersion(parsing: "1.4")
        #expect(twoComponent.major == 1)
        #expect(twoComponent.minor == 4)
        #expect(twoComponent.patch == 0)
    }
    
    @Test
    func parsesThreeComponentVersions() throws {
        let threeComponent = try SemanticVersion(parsing: "2.5.9")
        #expect(threeComponent.major == 2)
        #expect(threeComponent.minor == 5)
        #expect(threeComponent.patch == 9)
    }
    
    @Test
    func stableNewerThanBeta() throws {
        let beta = try SemanticVersion(parsing: "1.0.0-beta.1")
        let release = try SemanticVersion(parsing: "1.0.0")
        
        #expect(beta < release)
    }
    
    @Test
    func releaseNewerThanRC() throws {
        let rc = try SemanticVersion(parsing: "1.0.0-rc.1")
        let release = try SemanticVersion(parsing: "1.0.0")
        
        #expect(rc < release)
    }
    
    @Test
    func betaNewerThanAlpha() throws {
        let alpha = try SemanticVersion(parsing: "1.0.0-alpha.1")
        let beta = try SemanticVersion(parsing: "1.0.0-beta.1")
        
        #expect(alpha < beta)
    }
    
    @Test
    func patchNewerThanRelease() throws {
        let release = try SemanticVersion(parsing: "1.0.0")
        let patch = try SemanticVersion(parsing: "1.0.0-patch.1")
        
        #expect(release < patch)
    }
    
    @Test
    func acceptsVersionPrefix() throws {
        let version = try SemanticVersion(parsing: "v3.2.1")
        #expect(version.description == "3.2.1")
    }
}
