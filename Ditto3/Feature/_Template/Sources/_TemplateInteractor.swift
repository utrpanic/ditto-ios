import Combine

@MainActor
protocol _TemplatePresentable: AnyObject {}

@MainActor
protocol _TemplateInteractable: ObservableObject {
  var state: _TemplateState { get }
  func didTapCountUp()
}

@MainActor
final class _TemplateInteractor: _TemplateInteractable, ObservableObject {
  private let dependency: _TemplateDependency
  @Published private(set) var state = _TemplateState()
  weak var presenter: _TemplatePresentable?
  weak var listener: _TemplateListener?

  init(dependency: _TemplateDependency) {
    self.dependency = dependency
  }

  func didTapCountUp() {
    state.count += 1
  }
}
