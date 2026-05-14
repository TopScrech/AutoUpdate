// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "AutoUpdate",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "AutoUpdate",
            targets: ["AutoUpdate"]
        )
    ],
    targets: [
        .target(
            name: "AutoUpdate"
        ),
        .testTarget(
            name: "AutoUpdateTests",
            dependencies: ["AutoUpdate"]
        )
    ],
    swiftLanguageModes: [.v6]
)
