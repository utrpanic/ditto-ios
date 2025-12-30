import Feature

// Presentable + Routing
@MainActor
protocol _TemplatePresentable: AnyObject {
}

// Should conform to the child listener.
@MainActor
final class _TemplateInteractor: _TemplateInteractable {
  private let dependency: _TemplateDependency
  weak var presenter: _TemplatePresentable?
  weak var listener: _TemplateListener?
  
  init(dependency: _TemplateDependency) {
    self.dependency = dependency
  }
}
