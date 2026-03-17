import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Core",
  options: .default,
  targets: [
    .coreTarget(
      name: "Entity",
      sourcePath: "Entity",
      dependencies: []
    ),
    .coreTarget(
      name: "Repository",
      sourcePath: "Repository/Interface",
      dependencies: [
        .target(name: "Entity"),
      ]
    ),
    .coreTarget(
      name: "RepositoryImp",
      sourcePath: "Repository/Implementation",
      dependencies: [
        .platform(target: "Platform"),
        .target(name: "Entity"),
        .target(name: "Repository"),
      ]
    ),
    .coreUnitTestsTarget(
      name: "RepositoryImpTests",
      sourcePath: "Repository/Tests",
      dependencies: [
        .platform(target: "Platform"),
        .platform(target: "PlatformTestSupport"),
        .target(name: "Entity"),
        .target(name: "Repository"),
        .target(name: "RepositoryImp"),
      ]
    ),
    .coreUnitTestsTarget(
      name: "RepositoryImpTestsOnLive",
      sourcePath: "Repository/TestsOnLive",
      dependencies: [
        .platform(target: "Platform"),
        .target(name: "Entity"),
        .target(name: "Repository"),
        .target(name: "RepositoryImp"),
      ]
    ),
  ],
  schemes: [
    .scheme(
      name: "Core",
      buildAction: .buildAction(
        targets: [
          "Entity",
          "Repository",
          "RepositoryImp",
        ]
      ),
      testAction: .targets([
        .testableTarget(target: "RepositoryImpTests"),
      ])
    ),
  ]
)

private extension Target {
  static func coreTarget(
    name: String,
    sourcePath: String,
    resourcePath: String? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    iOSTarget(
      name: name,
      product: resourcePath == nil ? .staticLibrary : .staticFramework,
      bundleId: "Core.\(name)",
      sourcePath: sourcePath,
      resourcePath: resourcePath,
      dependencies: dependencies
    )
  }

  static func coreUnitTestsTarget(
    name: String,
    sourcePath: String,
    resourcePath: String? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    iOSTarget(
      name: name,
      product: .unitTests,
      bundleId: "Core.\(name)",
      sourcePath: sourcePath,
      resourcePath: resourcePath,
      dependencies: dependencies
    )
  }
}
