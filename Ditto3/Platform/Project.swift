import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Platform",
  options: .default,
  targets: [
    .platformFrameworkTarget(
      name: "Platform",
      sourcePath: "Sources",
      dependencies: []
    ),
    .platformFrameworkTarget(
      name: "PlatformTestSupport",
      sourcePath: "TestSupport",
      dependencies: [
        .target(name: "Platform"),
      ]
    ),
    .platformUnitTestsTarget(
      name: "PlatformTests",
      sourcePath: "Tests",
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
    sourcePath: String,
    resourcePath: String? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    iOSTarget(
      name: name,
      product: .framework,
      bundleId: "Platform.\(name)",
      sourcePath: sourcePath,
      resourcePath: resourcePath,
      dependencies: dependencies
    )
  }

  static func platformUnitTestsTarget(
    name: String,
    sourcePath: String,
    resourcePath: String? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    iOSTarget(
      name: name,
      product: .unitTests,
      bundleId: "Platform.\(name)",
      sourcePath: sourcePath,
      resourcePath: resourcePath,
      dependencies: dependencies
    )
  }
}
