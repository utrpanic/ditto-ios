import RIBsLite
import SwiftUI
import UIKit

@MainActor
final class _TemplateViewController: UIHostingController<StateReader<_TemplateState, _TemplateView>>, _TemplatePresentable {
  private let interactor: _TemplateInteractable

  init(interactor: _TemplateInteractable) {
    self.interactor = interactor
    super.init(rootView: StateReader(store: interactor.store) { state in
      _TemplateView(state: state, sendAction: interactor.sendAction)
    })
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
