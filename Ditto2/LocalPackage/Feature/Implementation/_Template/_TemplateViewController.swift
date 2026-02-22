import Feature
import UIKit

// Interactable + PresentableListener
@MainActor
protocol _TemplateInteractable {
}

final class _TemplateViewController: UIViewController, _TemplatePresentable {
  private let interactor: _TemplateInteractable
  
  init(interactor: _TemplateInteractable) {
    self.interactor = interactor
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
  }
}
