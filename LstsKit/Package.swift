// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LstsKit",
  platforms: [.macOS(.v11), .iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "LstsKit",
            targets: ["LstsKit"]),
      .library(
          name: "LstsServerKit",
          targets: ["LstsServerKit"]),
      .library(
          name: "LstsUIKit",
          targets: ["LstsUIKit"]),
      .executable(name: "lstsd", targets: ["lstsd"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
      .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LstsKit",
            dependencies: []),
      .target(
          name: "LstsUIKit",
          dependencies: ["LstsKit"]),
      .target(
          name: "LstsServerKit",
          dependencies: ["LstsKit",
                         .product(name: "Vapor", package: "vapor")]),
        .target(name: "lstsd", dependencies: ["LstsServerKit"]),
        .testTarget(
            name: "LstsKitTests",
            dependencies: ["LstsKit"]),
    ]
)
