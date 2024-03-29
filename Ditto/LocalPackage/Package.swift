// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LocalPackage",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "DittoIO", targets: ["DittoIO"]),
    .library(name: "DittoIOImp", targets: ["DittoIO"]),
    .library(name: "DittoIOTestSupport", targets: ["DittoIOTestSupport"])
  ],
  targets: [
    .target(name: "DittoIO", path: "DittoIO/Interface"),
    .target(name: "DittoIOImp", dependencies: ["DittoIO"], path: "DittoIO/Implementation"),
    .target(name: "DittoIOTestSupport", dependencies: ["DittoIO"], path: "DittoIO/TestSupport"),
    .testTarget(name: "DittoIOImpTests", dependencies: ["DittoIOImp"], path: "DittoIO/Tests"),
  ]
)
