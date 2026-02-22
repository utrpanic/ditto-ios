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
  ]
)
