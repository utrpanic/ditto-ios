import SwiftUI
import UIKit

@MainActor
final class SearchViewController: UIHostingController<SearchView>, SearchControllable {
  private let interactor: SearchInteractable

  init(interactor: SearchInteractable) {
    self.interactor = interactor
    super.init(rootView: SearchView(store: interactor.store, interactor: interactor))
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
