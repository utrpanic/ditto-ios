import Feature
import UIKit

// Repository + Child Buildable
public protocol _TemplateDependency: Sendable {
}

public final class _TemplateBuilder: _TemplateBuildable {
  private let dependency: _TemplateDependency

  public init(dependency: _TemplateDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: _TemplateListener?) -> UIViewController {
    let interactor = _TemplateInteractor(dependency: self.dependency)
    let viewController = _TemplateViewController(interactor: interactor)
    interactor.presenter = viewController
    interactor.listener = listener
    return viewController
  }
}
