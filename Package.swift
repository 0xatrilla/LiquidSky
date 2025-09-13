// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LiquidSky",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .executable(name: "LiquidSky", targets: ["LiquidSky"]),
    ],
    dependencies: [
        .package(url: "https://github.com/MasterJ93/ATProtoKit", from: "0.31.2"),
        .package(url: "https://github.com/evgenyneu/keychain-swift", from: "24.0.0"),
        .package(url: "https://github.com/Dimillian/AppRouter.git", from: "1.0.2"),
        .package(url: "https://github.com/kean/Nuke", from: "12.8.0"),
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.1"),
        .package(url: "https://github.com/vtourraine/AcknowList", from: "3.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "LiquidSky",
            dependencies: [
                .product(name: "ATProtoKit", package: "ATProtoKit"),
                .product(name: "KeychainSwift", package: "keychain-swift"),
                .product(name: "AppRouter", package: "AppRouter"),
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "NukeUI", package: "Nuke"),
                .product(name: "ViewInspector", package: "ViewInspector"),
                .product(name: "AcknowList", package: "AcknowList"),
            ],
            path: "LiquidSky",
            linkerSettings: [
                .unsafeFlags(["-weak_framework", "FoundationModels"], .when(platforms: [.iOS]))
            ]
        ),
    ]
)