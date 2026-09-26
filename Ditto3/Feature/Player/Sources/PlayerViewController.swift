import Combine
import RIBsLite
import SwiftUI
import UIKit

@MainActor
final class PlayerViewController: UIHostingController<StateReader<PlayerState, PlayerView>>, PlayerViewControllable {
  let interactor: PlayerInteractable
  private var cancellable: AnyCancellable?
  private var visibilityObserver: ((Bool) -> Void)?

  init(interactor: PlayerInteractable) {
    self.interactor = interactor
    super.init(rootView: StateReader(store: interactor.store) { state in
      PlayerView(state: state, sendAction: interactor.sendAction)
    })
    view.backgroundColor = .clear
    updateVisibility(for: interactor.store.state)
    cancellable = interactor.store.stateDidChange
      .removeDuplicates()
      .sink { [weak self] state in
        self?.updateVisibility(for: state)
      }
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func observeVisibility(_ observer: @escaping (Bool) -> Void) {
    visibilityObserver = observer
    observer(interactor.store.state.session != nil)
  }

  private func updateVisibility(for state: PlayerState) {
    visibilityObserver?(state.session != nil)
  }
}
