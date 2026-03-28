import UIKit

public protocol NewDependency {}

public final class NewBuilder: NewBuildable {
  private let dependency: NewDependency

  public init(dependency: NewDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: NewListener?) -> UIViewController {
    _ = dependency
    _ = listener
    return NewViewController()
  }
}
