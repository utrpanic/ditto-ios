import RIBsLite
import SwiftUI
import UIKit

@MainActor
final class SearchViewController: UIHostingController<StateReader<SearchState, SearchView>>, SearchControllable {
  private let interactor: SearchInteractable

  init(interactor: SearchInteractable) {
    self.interactor = interactor
    super.init(rootView: StateReader(store: interactor.store) { state in
      SearchView(state: state, sendAction: interactor.sendAction)
    })
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
