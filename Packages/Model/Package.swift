// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Model",
  platforms: [.iOS(.v26), .macOS(.v26)],
  products: [
    .library(name: "Client", targets: ["Client"]),
    .library(name: "Models", targets: ["Models"]),
    .library(name: "Auth", targets: ["Auth"]),
    .library(name: "User", targets: ["User"]),
    .library(name: "Destinations", targets: ["Destinations"]),
    .library(name: "InAppPurchase", targets: ["InAppPurchase"]),
  ],
  dependencies: [
    .package(url: "https://github.com/MasterJ93/ATProtoKit", from: "0.28.0"),
    .package(url: "https://github.com/evgenyneu/keychain-swift", from: "24.0.0"),
    .package(url: "https://github.com/Dimillian/AppRouter.git", from: "1.0.2"),
    .package(url: "https://github.com/kean/Nuke", from: "12.8.0"),
  ],
  targets: [
    .target(
      name: "Client",
      dependencies: [
        .product(name: "ATProtoKit", package: "ATProtoKit")
      ]
    ),
    .target(
      name: "Models",
      dependencies: [
        .product(name: "ATProtoKit", package: "ATProtoKit"),
        .product(name: "Nuke", package: "Nuke"),
        .product(name: "NukeUI", package: "Nuke"),
        "Client",
      ]
    ),
    .target(
      name: "Auth",
      dependencies: [
        .product(name: "ATProtoKit", package: "ATProtoKit"),
        .product(name: "KeychainSwift", package: "keychain-swift"),
        "Models",
      ]
    ),
    .testTarget(
      name: "AuthTests",
      dependencies: ["Auth"]
    ),
    .target(
      name: "User",
      dependencies: [
        .product(name: "ATProtoKit", package: "ATProtoKit"),
        "Client",
      ]
    ),
    .target(
      name: "Destinations",
      dependencies: ["Models", "AppRouter"]
    ),
    .target(
      name: "InAppPurchase",
      dependencies: []
    ),
  ]
)
