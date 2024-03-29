// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "storageclient",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "storageclient",
            targets: ["storageclient"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/SwifterSwift/SwifterSwift.git", exact: "5.2.0"),
        .package(path: "../ToolboxStorageClient"),
        .package(path: "../tools")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "storageclient",
            dependencies: ["ToolboxStorageClient", "SwifterSwift", "tools"]),
        .testTarget(
            name: "storageclientTests",
            dependencies: ["storageclient"]),
    ]
)
