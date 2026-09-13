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
    .platformFrameworkTarget(
      name: "PlaybackImp",
      sourcePath: "Playback/Implementation",
      dependencies: [
        .core(target: "Entity"),
        .core(target: "Playback"),
      ]
    ),
    .platformUnitTestsTarget(
      name: "PlatformTests",
      sourcePath: "Tests",
      dependencies: [
        .target(name: "Platform"),
      ]
    ),
    .platformUnitTestsTarget(
      name: "PlaybackImpTests",
      sourcePath: "Playback/Tests",
      dependencies: [
        .core(target: "Entity"),
        .core(target: "Playback"),
        .target(name: "PlaybackImp"),
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
          "PlaybackImp",
        ]
      ),
      testAction: .targets([
        .testableTarget(target: "PlatformTests"),
        .testableTarget(target: "PlaybackImpTests"),
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
      product: resourcePath == nil ? .staticLibrary : .staticFramework,
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
