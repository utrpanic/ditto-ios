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
  ]
)
