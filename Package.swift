// swift-tools-version: 6.3.2
import PackageDescription

let package = Package(
    name: "AutoUpdate",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .library(name: "AutoUpdate", targets: ["AutoUpdate"])
    ],
    targets: [
        .target(name: "AutoUpdate"),
        .testTarget(name: "AutoUpdateTests", dependencies: ["AutoUpdate"])
    ],
    swiftLanguageModes: [.v6]
)
