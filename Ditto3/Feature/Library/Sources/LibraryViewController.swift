import RIBsLite
import SwiftUI
import UIKit

@MainActor
final class LibraryViewController: UIHostingController<StateReader<LibraryState, LibraryView>>, LibraryControllable {
  let interactor: LibraryInteractable

  init(interactor: LibraryInteractable) {
    self.interactor = interactor
    super.init(rootView: StateReader(store: interactor.store) { state in
      LibraryView(state: state, sendAction: interactor.sendAction)
    })
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
