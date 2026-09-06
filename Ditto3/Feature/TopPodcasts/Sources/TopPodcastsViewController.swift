import RIBsLite
import SwiftUI
import UIKit

@MainActor
final class TopPodcastsViewController: UIHostingController<StateReader<TopPodcastsState, TopPodcastsView>>, TopPodcastsControllable {
  private let interactor: TopPodcastsInteractable

  init(interactor: TopPodcastsInteractable) {
    self.interactor = interactor
    super.init(rootView: StateReader(store: interactor.store) { state in
      TopPodcastsView(state: state, sendAction: interactor.sendAction)
    })
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
