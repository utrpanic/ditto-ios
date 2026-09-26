import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Architecture",
  options: .default,
  targets: [
    .architectureTarget(
      name: "RIBsLite",
      sourcePath: "RIBsLite",
      dependencies: []
    ),
  ],
  schemes: [
    .scheme(
      name: "Architecture",
      buildAction: .buildAction(
        targets: [
          "RIBsLite",
        ]
      )
    ),
  ]
)

private extension Target {
  static func architectureTarget(
    name: String,
    sourcePath: String,
    resourcePath: String? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    iOSTarget(
      name: name,
      product: resourcePath == nil ? .staticLibrary : .staticFramework,
      bundleId: "Architecture.\(name)",
      sourcePath: sourcePath,
      resourcePath: resourcePath,
      dependencies: dependencies
    )
  }
}
