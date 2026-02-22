import ProjectDescription
import ProjectDescriptionHelpers

func featureTarget(
  name: String,
  bundleSuffix: String,
  sourcePath: String,
  resourcesPath: String? = nil,
  dependencies: [TargetDependency] = [.project(target: "Core", path: "../Core")]
) -> Target {
  .target(
    name: name,
    destinations: .iOS,
    product: .framework,
    bundleId: AppConfig.bundleId(bundleSuffix),
    infoPlist: .default,
    sources: ["\(sourcePath)/Sources/**"],
    resources: resourcesPath.map { ["\($0)/**"] } ?? [],
    dependencies: dependencies
  )
}

let project = Project(
  name: "Feature",
  options: .default,
  targets: [
    featureTarget(
      name: "Bookmarks",
      bundleSuffix: "feature.bookmarks",
      sourcePath: "Bookmarks",
      resourcesPath: "Bookmarks/Resources"
    ),
    featureTarget(
      name: "New",
      bundleSuffix: "feature.new",
      sourcePath: "New",
      resourcesPath: "New/Resources"
    ),
    featureTarget(
      name: "Podcast",
      bundleSuffix: "feature.podcast",
      sourcePath: "Podcast",
      resourcesPath: "Podcast/Resources"
    ),
    featureTarget(
      name: "Search",
      bundleSuffix: "feature.search",
      sourcePath: "Search",
      resourcesPath: "Search/Resources",
      dependencies: [
        .project(target: "Core", path: "../Core"),
        .target(name: "Podcast"),
      ]
    ),
    featureTarget(
      name: "TopPodcasts",
      bundleSuffix: "feature.top-podcasts",
      sourcePath: "TopPodcasts",
      resourcesPath: "TopPodcasts/Resources"
    ),
  ]
)
