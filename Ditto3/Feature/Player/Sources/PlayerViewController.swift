import Combine
import RIBsLite
import SwiftUI
import UIKit

@MainActor
protocol PlayerControllable: ViewControllable {}

@MainActor
final class PlayerViewController: UIHostingController<StateReader<PlayerState, PlayerView>>, PlayerControllable {
  static let miniPlayerHeight: CGFloat = 68

  let interactor: PlayerInteractable
  private var cancellable: AnyCancellable?

  init(interactor: PlayerInteractable) {
    self.interactor = interactor
    super.init(rootView: StateReader(store: interactor.store) { state in
      PlayerView(state: state, sendAction: interactor.sendAction)
    })
    preferredContentSize = CGSize(width: 0, height: Self.miniPlayerHeight)
    view.backgroundColor = .clear
    updateVisibility(for: interactor.store.state)
    cancellable = interactor.store.$state
      .removeDuplicates()
      .sink { [weak self] state in
        self?.updateVisibility(for: state)
      }
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func updateVisibility(for state: PlayerState) {
    view.isHidden = state.session == nil
    view.isUserInteractionEnabled = state.session != nil
  }
}
