// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LocalPackage",
  platforms: [.iOS(.v26)],
  products: [
    .library(
      name: "LocalLibrary",
      targets: [
        "Feature",
        "FeatureImp",
        "Model",
        "Repository",
        "RepositoryImp",
      ]
    ),
    .library(name: "Feature", targets: ["Feature", "FeatureImp"]),
    .library(name: "Repository", targets: ["Repository", "RepositoryImp"]),
  ],
  dependencies: [
    
  ],
  targets: [
    .target(
      name: "Feature",
      dependencies: [
        "Model",
        "Repository",
      ],
      path: "Feature/Interface"
    ),
    .target(
      name: "FeatureImp",
      dependencies: [
        "Feature",
        "Model",
        "Repository",
      ],
      path: "Feature/Implementation",
      resources: [.process("Media.xcassets")]
    ),
    .testTarget(
      name: "FeatureImpTests",
      dependencies: [
        "Model",
        "Repository",
        "RepositoryTestSupport",
        "FeatureImp",
        "FeatureTestSupport",
      ],
      path: "Feature/Tests"
    ),
    .target(
      name: "FeatureTestSupport",
      dependencies: [
        "Model",
        "Repository",
        "Feature",
      ],
      path: "Feature/TestSupport"
    ),
    .target(
      name: "Model",
      path: "Model"
    ),
    .target(
      name: "Repository",
      dependencies: [
        "Model",
      ],
      path: "Repository/Interface"
    ),
    .target(
      name: "RepositoryImp",
      dependencies: [
        "Model",
        "Repository",
      ],
      path: "Repository/Implementation"
    ),
    .testTarget(
      name: "RepositoryImpTests",
      dependencies: [
        "Model",
        "Repository",
        "RepositoryImp",
      ],
      path: "Repository/Tests"
    ),
    .target(
      name: "RepositoryTestSupport",
      dependencies: [
        "Model",
        "Repository",
      ],
      path: "Repository/TestSupport"
    ),
  ]
)
