// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CanvasDeadlines",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CanvasDeadlines", targets: ["CanvasDeadlines"])
    ],
    targets: [
        .executableTarget(
            name: "CanvasDeadlines",
            path: "Sources/CanvasDeadlines"
        )
    ]
)
