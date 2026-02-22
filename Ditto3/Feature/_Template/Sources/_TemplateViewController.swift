import SwiftUI
import UIKit

@MainActor
protocol _TemplateInteractable {}

@MainActor
final class _TemplateViewController: UIHostingController<_TemplateView>, _TemplatePresentable {
  private let interactor: _TemplateInteractable

  init(interactor: _TemplateInteractable) {
    self.interactor = interactor
    super.init(rootView: _TemplateView())
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
