import ProjectDescription

public extension TargetDependency {
  static func architecture(target: String) -> Self {
    .project(target: target, path: "../Architecture")
  }

  static func core(target: String) -> Self {
    .project(target: target, path: "../Core")
  }

  static func feature(target: String) -> Self {
    .project(target: target, path: "../Feature")
  }

  static func platform(target: String) -> Self {
    .project(target: target, path: "../Platform")
  }
}
