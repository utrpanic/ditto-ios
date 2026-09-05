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
      name: "Bookmarks",
      sourcePath: "Bookmarks/Sources",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "BookmarksTests",
      sourcePath: "Bookmarks/Tests",
      dependencies: [
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Bookmarks"),
      ]
    ),
    .featureTarget(
      name: "Main",
      sourcePath: "Main/Sources",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Bookmarks"),
        .target(name: "New"),
        .target(name: "Search"),
        .target(name: "TopPodcasts"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "MainTests",
      sourcePath: "Main/Tests",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Bookmarks"),
        .target(name: "Main"),
        .target(name: "New"),
        .target(name: "Search"),
        .target(name: "TopPodcasts"),
      ]
    ),
    .featureTarget(
      name: "New",
      sourcePath: "New/Sources",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "NewTests",
      sourcePath: "New/Tests",
      dependencies: [
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "New"),
      ]
    ),
    .featureTarget(
      name: "Podcast",
      sourcePath: "Podcast/Sources",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "PodcastTests",
      sourcePath: "Podcast/Tests",
      dependencies: [
        .core(target: "Entity"),
        .core(target: "Repository"),
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
        .target(name: "Podcast"),
        .target(name: "Search"),
      ]
    ),
    .featureTarget(
      name: "TopPodcasts",
      sourcePath: "TopPodcasts/Sources",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Podcast"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "TopPodcastsTests",
      sourcePath: "TopPodcasts/Tests",
      dependencies: [
        .architecture(target: "RIBsLite"),
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Podcast"),
        .target(name: "TopPodcasts"),
      ]
    ),
  ],
  schemes: [
    .scheme(
      name: "Feature",
      buildAction: .buildAction(
        targets: [
          "Bookmarks",
          "Episode",
          "Main",
          "New",
          "Podcast",
          "Search",
          "TopPodcasts",
        ]
      ),
      testAction: .targets([
        .testableTarget(target: "BookmarksTests"),
        .testableTarget(target: "EpisodeTests"),
        .testableTarget(target: "MainTests"),
        .testableTarget(target: "NewTests"),
        .testableTarget(target: "PodcastTests"),
        .testableTarget(target: "SearchTests"),
        .testableTarget(target: "TopPodcastsTests"),
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
