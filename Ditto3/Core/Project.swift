import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Core",
  options: .default,
  targets: [
    .coreFrameworkTarget(
      name: "Entity",
      sourcesPath: "Entity",
      dependencies: []
    ),
    .coreFrameworkTarget(
      name: "Repository",
      sourcesPath: "Repository/Interface",
      dependencies: [
        .target(name: "Entity"),
      ]
    ),
    .coreFrameworkTarget(
      name: "RepositoryImp",
      sourcesPath: "Repository/Implementation",
      dependencies: [
        .platform(target: "Platform"),
        .target(name: "Entity"),
        .target(name: "Repository"),
      ]
    ),
    .coreUnitTestsTarget(
      name: "RepositoryImpTests",
      sourcesPath: "Repository/Tests",
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
      sourcesPath: "Repository/TestsOnLive",
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
  static func coreFrameworkTarget(
    name: String,
    sourcesPath: String,
    resourcesPath: String? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    iOSTarget(
      name: name,
      product: .framework,
      bundleId: "Core.\(name)",
      sourcesPath: sourcesPath,
      resourcesPath: resourcesPath,
      dependencies: dependencies
    )
  }

  static func coreUnitTestsTarget(
    name: String,
    sourcesPath: String,
    resourcesPath: String? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    iOSTarget(
      name: name,
      product: .unitTests,
      bundleId: "Core.\(name)",
      sourcesPath: sourcesPath,
      resourcesPath: resourcesPath,
      dependencies: dependencies
    )
  }
}
