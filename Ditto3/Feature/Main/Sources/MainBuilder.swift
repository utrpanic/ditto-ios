import UIKit

public protocol MainDependency: Sendable {}

public final class MainBuilder: MainBuildable {
  private let dependency: MainDependency

  public init(dependency: MainDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: MainListener?) -> UIViewController {
    _ = dependency
    _ = listener
    return MainViewController()
  }
}
