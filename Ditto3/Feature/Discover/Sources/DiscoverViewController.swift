import RIBsLite
import SwiftUI
import UIKit

@MainActor
final class DiscoverViewController: UIHostingController<StateReader<DiscoverState, DiscoverView>>, DiscoverControllable {
  private let interactor: DiscoverInteractable

  init(interactor: DiscoverInteractable) {
    self.interactor = interactor
    super.init(rootView: StateReader(store: interactor.store) { state in
      DiscoverView(state: state, sendAction: interactor.sendAction)
    })
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
