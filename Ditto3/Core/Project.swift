import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Core",
  options: .default,
  targets: [
    .coreFrameworkTarget(
      name: "Entity",
      sources: ["Entity/**"],
      dependencies: []
    ),
    .coreFrameworkTarget(
      name: "Repository",
      sources: ["Repository/Interface/**"],
      dependencies: [
        .target(name: "Entity"),
      ]
    ),
    .coreFrameworkTarget(
      name: "RepositoryImp",
      sources: ["Repository/Implementation/**"],
      dependencies: [
        .target(name: "Entity"),
        .target(name: "Repository"),
        .project(target: "Platform", path: "../Platform"),
      ]
    ),
    .coreUnitTestsTarget(
      name: "RepositoryImpTests",
      sources: ["Repository/Tests/**"],
      dependencies: [
        .target(name: "Entity"),
        .target(name: "Repository"),
        .target(name: "RepositoryImp"),
        .project(target: "Platform", path: "../Platform"),
        .project(target: "PlatformTestSupport", path: "../Platform"),
      ]
    ),
    .coreUnitTestsTarget(
      name: "RepositoryImpTestsOnLive",
      sources: ["Repository/TestsOnLive/**"],
      dependencies: [
        .target(name: "Entity"),
        .target(name: "Repository"),
        .target(name: "RepositoryImp"),
        .project(target: "Platform", path: "../Platform"),
      ]
    ),
  ]
)

private extension Target {
  static func coreFrameworkTarget(
    name: String,
    sources: SourceFilesList,
    dependencies: [TargetDependency]
  ) -> Target {
    coreTarget(name: name, product: .framework, sources: sources, dependencies: dependencies)
  }

  static func coreUnitTestsTarget(
    name: String,
    sources: SourceFilesList,
    dependencies: [TargetDependency]
  ) -> Target {
    coreTarget(name: name, product: .unitTests, sources: sources, dependencies: dependencies)
  }
  
  private static func coreTarget(
    name: String,
    product: Product,
    sources: SourceFilesList,
    dependencies: [TargetDependency]
  ) -> Target {
    .target(
      name: name,
      destinations: .iOS,
      product: product,
      bundleId: "Core.\(name)",
      sources: sources,
      dependencies: dependencies
    )
  }
}
