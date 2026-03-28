import UIKit

public protocol SearchDependency {}

public final class SearchBuilder: SearchBuildable {
  private let dependency: SearchDependency

  public init(dependency: SearchDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: SearchListener?) -> UIViewController {
    _ = dependency
    _ = listener
    return SearchViewController()
  }
}
