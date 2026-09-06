import RIBsLite

enum _TemplateAction {
  case countUp
}

@MainActor
protocol _TemplatePresentable: AnyObject {}

@MainActor
protocol _TemplateInteractable: AnyObject {
  var store: StateStore<_TemplateState> { get }
  func sendAction(_ action: _TemplateAction)
}

@MainActor
final class _TemplateInteractor: _TemplateInteractable {
  private let dependency: _TemplateDependency
  let store = StateStore(_TemplateState())
  weak var presenter: _TemplatePresentable?
  weak var listener: _TemplateListener?

  init(dependency: _TemplateDependency) {
    self.dependency = dependency
  }

  func sendAction(_ action: _TemplateAction) {
    switch action {
    case .countUp:
      store.state.count += 1
    }
  }
}
