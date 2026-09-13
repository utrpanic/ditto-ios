import RIBsLite

public protocol LatestDependency {}

public final class LatestBuilder: LatestBuildable {
  private let dependency: LatestDependency

  public init(dependency: LatestDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: LatestListener?) -> ViewControllable {
    _ = dependency
    _ = listener
    return LatestViewController()
  }
}
