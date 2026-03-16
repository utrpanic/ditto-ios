import ProjectDescription

public extension TargetDependency {
  static func platform(target: String) -> Self {
    .project(target: target, path: "../Platform")
  }
  
  static func core(target: String) -> Self {
    .project(target: target, path: "../Core")
  }

  static func feature(target: String) -> Self {
    .project(target: target, path: "../Feature")
  }
}
