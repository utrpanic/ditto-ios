import ProjectDescription

public extension Target {
  static func iOSTarget(
    name: String,
    product: Product,
    bundleId: String,
    sourcesPath: String,
    resourcesPath: String?,
    dependencies: [TargetDependency]
  ) -> Target {
    .target(
      name: name,
      destinations: .iOS,
      product: product,
      bundleId: bundleId,
      sources: ["\(sourcesPath)/**"],
      resources: resourcesPath.map { ["\($0)/**"] } ?? [],
      dependencies: dependencies
    )
  }    
}
