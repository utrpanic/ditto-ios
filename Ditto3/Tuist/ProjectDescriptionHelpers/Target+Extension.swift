import ProjectDescription

public extension Target {
  static func iOSTarget(
    name: String,
    product: Product,
    bundleId: String,
    sourcePath: String,
    resourcePath: String?,
    dependencies: [TargetDependency]
  ) -> Target {
    .target(
      name: name,
      destinations: .iOS,
      product: product,
      bundleId: bundleId,
      sources: ["\(sourcePath)/**"],
      resources: resourcePath.map { ["\($0)/**"] } ?? [],
      dependencies: dependencies
    )
  }    
}
