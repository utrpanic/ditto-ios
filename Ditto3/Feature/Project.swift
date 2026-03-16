import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Feature",
  options: .default,
  targets: [
    // .featureFrameworkTarget(
    //   name: "Bookmarks",
    //   sourcesPath: "Bookmarks/Sources",
    //   resourcesPath: "Bookmarks/Resources",
    //   dependencies: [
    //     .core(target: "Entity"),
    //     .core(target: "Repository"),
    //   ]
    // ),
    // .featureFrameworkTarget(
    //   name: "New",
    //   sourcesPath: "New/Sources",
    //   resourcesPath: "New/Resources",
    //   dependencies: [
    //     .core(target: "Entity"),
    //     .core(target: "Repository"),
    //   ]
    // ),
    // .featureFrameworkTarget(
    //   name: "Podcast",
    //   sourcesPath: "Podcast/Sources",
    //   resourcesPath: "Podcast/Resources",
    //   dependencies: [
    //     .core(target: "Entity"),
    //     .core(target: "Repository"),
    //   ]
    // ),
    // .featureFrameworkTarget(
    //   name: "Search",
    //   sourcesPath: "Search/Sources",
    //   resourcesPath: "Search/Resources",
    //   dependencies: [
    //     .core(target: "Entity"),
    //     .core(target: "Repository"),
    //     .target(name: "Podcast"),
    //   ]
    // ),
    .featureFrameworkTarget(
      name: "TopPodcasts",
      sourcesPath: "TopPodcasts/Sources",
      resourcesPath: "TopPodcasts/Resources",
      dependencies: [
        .core(target: "Entity"),
        .core(target: "Repository"),
      ]
    ),
    .featureUnitTestsTarget(
      name: "TopPodcastsTests",
      sourcesPath: "TopPodcasts/Tests",
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
  static func featureFrameworkTarget(
    name: String,
    sourcesPath: String,
    resourcesPath: String? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    iOSTarget(
      name: name,
      product: .framework,
      bundleId: "Feature.\(name)",
      sourcesPath: sourcesPath,
      resourcesPath: resourcesPath,
      dependencies: dependencies
    )
  }

  static func featureUnitTestsTarget(
    name: String,
    sourcesPath: String,
    resourcesPath: String? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    iOSTarget(
      name: name,
      product: .unitTests,
      bundleId: "Feature.\(name)",
      sourcesPath: sourcesPath,
      resourcesPath: resourcesPath,
      dependencies: dependencies
    )
  }
}
