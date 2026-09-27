import RIBsLite
import SwiftUI
import UIKit

@MainActor
final class PlayerViewController: UIHostingController<StateReader<PlayerState, PlayerView>>, PlayerViewControllable {
  let interactor: PlayerInteractable

  init(interactor: PlayerInteractable) {
    self.interactor = interactor
    super.init(rootView: StateReader(store: interactor.store) { state in
      PlayerView(state: state, sendAction: interactor.sendAction)
    })
    view.backgroundColor = .clear
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
