// swift-tools-version: 6.2

import PackageDescription

private let projectName = "TEx"

// Usage of the `darwinsdk` target is only available on Apple platforms,
//  and macOS is the only Apple platform supported by this package.
#if os(macOS)
    let platforms: [SupportedPlatform]? = [.macOS(.v13)]
    let darwinSDKDependency: Target.Dependency? = "DarwinSDK"
    let darwinSDKTarget: Target? = .target(
        name: "DarwinSDK",
        dependencies: [
            .product(name: "SwiftBuild", package: "swift-build")
        ]
    )
#else
    let platforms: [SupportedPlatform]? = nil
    let darwinSDKDependency: Target.Dependency? = nil
    let darwinSDKTarget: Target? = nil
#endif

let package = Package(
    name: projectName,
    platforms: platforms,
    products: [
        .executable(name: projectName, targets: [projectName]),
        .library(name: "DarwinSDK", targets: ["DarwinSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.1"),
        .package(
            url: "https://github.com/swiftlang/swift-build.git",
            revision: "swift-DEVELOPMENT-SNAPSHOT-2025-07-18-a"
        ),
    ],
    targets: [
        darwinSDKTarget,
        .executableTarget(
            name: projectName,
            dependencies: [
                darwinSDKDependency,
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ].compactMap({ $0 }),
            path: "Sources/CLI",
        ),
    ].compactMap({ $0 })
)
