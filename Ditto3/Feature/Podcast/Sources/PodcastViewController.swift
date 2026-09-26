import RIBsLite
import SwiftUI
import UIKit

@MainActor
final class PodcastViewController: UIHostingController<StateReader<PodcastState, PodcastView>>, PodcastControllable {
  let interactor: PodcastInteractable

  init(interactor: PodcastInteractable) {
    self.interactor = interactor
    super.init(rootView: StateReader(store: interactor.store) { state in
      PodcastView(state: state, sendAction: interactor.sendAction)
    })
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
