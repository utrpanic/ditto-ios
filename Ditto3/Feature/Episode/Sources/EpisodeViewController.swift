import RIBsLite
import SwiftUI
import UIKit

@MainActor
final class EpisodeViewController: UIHostingController<StateReader<EpisodeState, EpisodeView>>, EpisodeControllable {
  let interactor: EpisodeInteractable

  init(interactor: EpisodeInteractable) {
    self.interactor = interactor
    super.init(rootView: StateReader(store: interactor.store) { state in
      EpisodeView(state: state)
    })
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
