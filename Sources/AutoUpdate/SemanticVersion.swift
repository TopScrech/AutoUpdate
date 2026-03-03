import Foundation

public struct SemanticVersion: Comparable, Hashable, Sendable, CustomStringConvertible {
    public enum Identifier: Hashable, Sendable {
        case numeric(Int)
        case text(String)
    }
    
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: [Identifier]
    public let buildMetadata: [String]
    
    public init(
        major: Int,
        minor: Int,
        patch: Int,
        prerelease: [Identifier] = [],
        buildMetadata: [String] = []
    ) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.buildMetadata = buildMetadata
    }
    
    public init(parsing versionString: String) throws {
        let trimmed = versionString.trimmingCharacters(in: .whitespacesAndNewlines)
        let noPrefix = trimmed.hasPrefix("v") ? String(trimmed.dropFirst()) : trimmed
        let plusSplit = noPrefix.split(separator: "+", maxSplits: 1, omittingEmptySubsequences: false)
        let mainAndPrerelease = String(plusSplit[0])
        let buildSection = plusSplit.count > 1 ? String(plusSplit[1]) : nil
        
        let prereleaseSplit = mainAndPrerelease.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let mainSection = String(prereleaseSplit[0])
        let prereleaseSection = prereleaseSplit.count > 1 ? String(prereleaseSplit[1]) : nil
        
        let components = mainSection.split(separator: ".", omittingEmptySubsequences: false)
        guard (2...3).contains(components.count) else {
            throw AppUpdaterError.invalidVersionString(versionString)
        }
        
        guard let major = Int(components[0]), let minor = Int(components[1]) else {
            throw AppUpdaterError.invalidVersionString(versionString)
        }
        
        let patch = components.count == 3 ? Int(components[2]) : 0
        guard let patch else {
            throw AppUpdaterError.invalidVersionString(versionString)
        }
        
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = Self.parseIdentifiers(section: prereleaseSection)
        self.buildMetadata = buildSection?.split(separator: ".").map(String.init) ?? []
    }
    
    public var description: String {
        var value = "\(major).\(minor).\(patch)"
        if !prerelease.isEmpty {
            let label = prerelease.map {
                switch $0 {
                case .numeric(let number):
                    return String(number)
                case .text(let text):
                    return text
                }
            }.joined(separator: ".")
            value += "-\(label)"
        }
        if !buildMetadata.isEmpty {
            value += "+\(buildMetadata.joined(separator: "."))"
        }
        return value
    }
    
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        
        if lhs.prerelease.isEmpty && rhs.prerelease.isEmpty { return false }
        if lhs.prerelease.isEmpty { return false }
        if rhs.prerelease.isEmpty { return true }
        
        let maxCount = max(lhs.prerelease.count, rhs.prerelease.count)
        for index in 0..<maxCount {
            guard index < lhs.prerelease.count else { return true }
            guard index < rhs.prerelease.count else { return false }
            
            let left = lhs.prerelease[index]
            let right = rhs.prerelease[index]
            
            switch (left, right) {
            case (.numeric(let l), .numeric(let r)):
                if l != r { return l < r }
                
            case (.numeric, .text):
                return true
                
            case (.text, .numeric):
                return false
                
            case (.text(let l), .text(let r)):
                if l != r { return l < r }
            }
        }
        
        return false
    }
    
    private static func parseIdentifiers(section: String?) -> [Identifier] {
        guard let section, !section.isEmpty else { return [] }
        
        return section.split(separator: ".").map { value in
            if let intValue = Int(value) {
                return .numeric(intValue)
            }
            
            return .text(String(value))
        }
    }
}
