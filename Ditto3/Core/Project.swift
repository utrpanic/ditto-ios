import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Core",
  options: .default,
  targets: [
    .target(
      name: "Core",
      destinations: .iOS,
      product: .framework,
      bundleId: AppConfig.bundleId("core"),
      infoPlist: .default,
      sources: ["Sources/**"],
      dependencies: [
        .project(target: "Platform", path: "../Platform"),
      ]
    ),
    .target(
      name: "CoreTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: AppConfig.bundleId("core.tests"),
      infoPlist: .default,
      sources: ["Tests/**"],
      dependencies: [
        .target(name: "Core"),
        .project(target: "Platform", path: "../Platform"),
        .project(target: "PlatformTestSupport", path: "../Platform"),
      ]
    ),
    .target(
      name: "CoreTestsOnLive",
      destinations: .iOS,
      product: .unitTests,
      bundleId: AppConfig.bundleId("core.tests-on-live"),
      infoPlist: .default,
      sources: ["TestsOnLive/**"],
      dependencies: [
        .target(name: "Core"),
        .project(target: "Platform", path: "../Platform"),
      ]
    ),
  ]
)
