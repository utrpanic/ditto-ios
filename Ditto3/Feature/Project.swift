import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Feature",
  options: .default,
  targets: [
    .featureTarget(
      name: "RIBsLite",
      sourcePath: "RIBsLite/Sources",
      dependencies: []
    ),
    .featureTarget(
      name: "Bookmarks",
      sourcePath: "Bookmarks/Sources",
      dependencies: [
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
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "RIBsLite"),
        .target(name: "TopPodcasts"),
        .target(name: "New"),
        .target(name: "Bookmarks"),
        .target(name: "Search"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "MainTests",
      sourcePath: "Main/Tests",
      dependencies: [
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "RIBsLite"),
        .target(name: "TopPodcasts"),
        .target(name: "New"),
        .target(name: "Bookmarks"),
        .target(name: "Search"),
        .target(name: "Main"),
      ]
    ),
    .featureTarget(
      name: "New",
      sourcePath: "New/Sources",
      dependencies: [
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
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "Podcast"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "SearchTests",
      sourcePath: "Search/Tests",
      dependencies: [
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
        .core(target: "Entity"),
        .core(target: "Repository"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "TopPodcastsTests",
      sourcePath: "TopPodcasts/Tests",
      dependencies: [
        .core(target: "Entity"),
        .core(target: "Repository"),
        .target(name: "TopPodcasts"),
      ]
    ),
  ],
  schemes: [
    .scheme(
      name: "Feature",
      buildAction: .buildAction(
        targets: [
          "RIBsLite",
          "Bookmarks",
          "Main",
          "New",
          "Podcast",
          "Search",
          "TopPodcasts",
        ]
      ),
      testAction: .targets([
        .testableTarget(target: "BookmarksTests"),
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
