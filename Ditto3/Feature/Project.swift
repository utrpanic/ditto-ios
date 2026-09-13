import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Feature",
  options: .default,
  targets: [
    .featureTarget(
      name: "Episode",
      sourcePath: "Episode/Sources",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "EpisodeTests",
      sourcePath: "Episode/Tests",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .target(name: "Episode"),
      ]
    ),
    .featureTarget(
      name: "Library",
      sourcePath: "Library/Sources",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Podcast"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "LibraryTests",
      sourcePath: "Library/Tests",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Podcast"),
        .target(name: "Library"),
      ]
    ),
    .featureTarget(
      name: "Main",
      sourcePath: "Main/Sources",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Discover"),
        .target(name: "Latest"),
        .target(name: "Library"),
        .target(name: "Search"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "MainTests",
      sourcePath: "Main/Tests",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Discover"),
        .target(name: "Main"),
        .target(name: "Latest"),
        .target(name: "Library"),
        .target(name: "Search"),
      ]
    ),
    .featureTarget(
      name: "Latest",
      sourcePath: "Latest/Sources",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "LatestTests",
      sourcePath: "Latest/Tests",
      dependencies: [
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Latest"),
      ]
    ),
    .featureTarget(
      name: "Podcast",
      sourcePath: "Podcast/Sources",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Episode"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "PodcastTests",
      sourcePath: "Podcast/Tests",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Episode"),
        .target(name: "Podcast"),
      ]
    ),
    .featureTarget(
      name: "Search",
      sourcePath: "Search/Sources",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Episode"),
        .target(name: "Podcast"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "SearchTests",
      sourcePath: "Search/Tests",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Episode"),
        .target(name: "Podcast"),
        .target(name: "Search"),
      ]
    ),
    .featureTarget(
      name: "Discover",
      sourcePath: "Discover/Sources",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Podcast"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "DiscoverTests",
      sourcePath: "Discover/Tests",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Podcast"),
        .target(name: "Discover"),
      ]
    ),
  ],
  schemes: [
    .scheme(
      name: "Feature",
      buildAction: .buildAction(
        targets: [
          "Discover",
          "Episode",
          "Main",
          "Latest",
          "Library",
          "Podcast",
          "Search",
        ]
      ),
      testAction: .targets([
        .testableTarget(target: "DiscoverTests"),
        .testableTarget(target: "EpisodeTests"),
        .testableTarget(target: "MainTests"),
        .testableTarget(target: "LatestTests"),
        .testableTarget(target: "LibraryTests"),
        .testableTarget(target: "PodcastTests"),
        .testableTarget(target: "SearchTests"),
      ])
    ),
  ]
)

private extension Target {
  static func featureTarget(
    name: String,
    sourcePath: String,
    resourcePath: String? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    iOSTarget(
      name: name,
      product: resourcePath == nil ? .staticLibrary : .staticFramework,
      bundleId: "Feature.\(name)",
      sourcePath: sourcePath,
      resourcePath: resourcePath,
      dependencies: dependencies
    )
  }

  static func featureUnitTestsTarget(
    name: String,
    sourcePath: String,
    resourcePath: String? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    iOSTarget(
      name: name,
      product: .unitTests,
      bundleId: "Feature.\(name)",
      sourcePath: sourcePath,
      resourcePath: resourcePath,
      dependencies: dependencies
    )
  }
}
