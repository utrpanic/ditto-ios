import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Feature",
  options: .default,
  targets: [
    .target(
      name: "_Template",
      destinations: .iOS,
      product: .framework,
      bundleId: AppConfig.bundleId("feature.template"),
      infoPlist: .default,
      sources: ["_Template/Sources/**"],
      resources: ["_Template/Resources/**"],
      dependencies: [
        .project(target: "Core", path: "../Core"),
      ]
    ),
    .target(
      name: "_TemplateTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: AppConfig.bundleId("feature.template.tests"),
      infoPlist: .default,
      sources: ["_Template/Tests/**"],
      dependencies: [
        .project(target: "Core", path: "../Core"),
        .target(name: "_Template"),
      ]
    ),
  ]
)
