import Core
import SwiftUI
import UIKit

// Repository + Child Buildable
public protocol _TemplateDependency: Sendable {
  var _templateRepository: _TemplateRepository { get }
}

public final class _TemplateBuilder: _TemplateBuildable {
  private let dependency: _TemplateDependency

  public init(dependency: _TemplateDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: _TemplateListener?) -> UIViewController {
    let interactor = _TemplateInteractor(dependency: dependency)
    let view = _TemplateView(interactor: interactor)
    let viewController = _TemplateViewController(rootView: view, retainables: [interactor])
    interactor.presenter = viewController
    interactor.listener = listener
    return viewController
  }
}
