import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Platform",
  options: .default,
  targets: [
    .target(
      name: "Platform",
      destinations: .iOS,
      product: .framework,
      bundleId: AppConfig.bundleId("platform"),
      infoPlist: .default,
      sources: ["Sources/**"],
      dependencies: []
    ),
    .target(
      name: "PlatformTestSupport",
      destinations: .iOS,
      product: .framework,
      bundleId: AppConfig.bundleId("platform.testsupport"),
      infoPlist: .default,
      sources: ["TestSupport/**"],
      dependencies: [
        .target(name: "Platform"),
      ]
    ),
    .target(
      name: "PlatformTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: AppConfig.bundleId("platform.tests"),
      infoPlist: .default,
      sources: ["Tests/**"],
      dependencies: [
        .target(name: "Platform"),
      ]
    ),
  ]
)
