@MainActor
protocol _TemplatePresentable: AnyObject {}

@MainActor
final class _TemplateInteractor: _TemplateInteractable {
  private let dependency: _TemplateDependency
  weak var presenter: _TemplatePresentable?
  weak var listener: _TemplateListener?

  init(dependency: _TemplateDependency) {
    self.dependency = dependency
  }
}
