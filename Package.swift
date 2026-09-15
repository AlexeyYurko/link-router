// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "link-router",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "RouterCore"),
        .executableTarget(
            name: "LinkRouter",
            dependencies: ["RouterCore"]
        ),
        .executableTarget(name: "RouterTests", dependencies: ["RouterCore"]),
    ]
)
