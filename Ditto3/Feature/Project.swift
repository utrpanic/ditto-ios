import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Feature",
  options: .default,
  targets: [
    // .featureTarget(
    //   name: "Bookmarks",
    //   sourcePath: "Bookmarks/Sources",
    //   resourcePath: "Bookmarks/Resources",
    //   dependencies: [
    //     .core(target: "Entity"),
    //     .core(target: "Repository"),
    //   ]
    // ),
    // .featureTarget(
    //   name: "New",
    //   sourcePath: "New/Sources",
    //   resourcePath: "New/Resources",
    //   dependencies: [
    //     .core(target: "Entity"),
    //     .core(target: "Repository"),
    //   ]
    // ),
    // .featureTarget(
    //   name: "Podcast",
    //   sourcePath: "Podcast/Sources",
    //   resourcePath: "Podcast/Resources",
    //   dependencies: [
    //     .core(target: "Entity"),
    //     .core(target: "Repository"),
    //   ]
    // ),
    // .featureTarget(
    //   name: "Search",
    //   sourcePath: "Search/Sources",
    //   resourcePath: "Search/Resources",
    //   dependencies: [
    //     .core(target: "Entity"),
    //     .core(target: "Repository"),
    //     .target(name: "Podcast"),
    //   ]
    // ),
    .featureTarget(
      name: "TopPodcasts",
      sourcePath: "TopPodcasts/Sources",
      resourcePath: "TopPodcasts/Resources",
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
          "Bookmarks",
          "New",
          "Podcast",
          "Search",
          "TopPodcasts",
        ]
      ),
      testAction: .targets([
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
