import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Platform",
  options: .default,
  targets: [
    .platformFrameworkTarget(
      name: "Platform",
      sourcesPath: "Sources",
      dependencies: []
    ),
    .platformFrameworkTarget(
      name: "PlatformTestSupport",
      sourcesPath: "TestSupport",
      dependencies: [
        .target(name: "Platform"),
      ]
    ),
    .platformUnitTestsTarget(
      name: "PlatformTests",
      sourcesPath: "Tests",
      dependencies: [
        .target(name: "Platform"),
      ]
    ),
  ],
  schemes: [
    .scheme(
      name: "Platform",
      buildAction: .buildAction(
        targets: [
          "Platform",
          "PlatformTestSupport",
        ]
      ),
      testAction: .targets([
        .testableTarget(target: "PlatformTests"),
      ])
    ),
  ]
)

private extension Target {
  static func platformFrameworkTarget(
    name: String,
    sourcesPath: String,
    resourcesPath: String? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    iOSTarget(
      name: name,
      product: .framework,
      bundleId: "Platform.\(name)",
      sourcesPath: sourcesPath,
      resourcesPath: resourcesPath,
      dependencies: dependencies
    )
  }

  static func platformUnitTestsTarget(
    name: String,
    sourcesPath: String,
    resourcesPath: String? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    iOSTarget(
      name: name,
      product: .unitTests,
      bundleId: "Platform.\(name)",
      sourcesPath: sourcesPath,
      resourcesPath: resourcesPath,
      dependencies: dependencies
    )
  }
}
