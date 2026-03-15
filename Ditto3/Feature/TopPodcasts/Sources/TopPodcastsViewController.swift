import SwiftUI
import UIKit

@MainActor
final class TopPodcastsViewController: UIHostingController<TopPodcastsView>, TopPodcastsPresentable {
  private let interactor: TopPodcastsInteractable
  private let stateStore: TopPodcastsViewStateStore

  init(interactor: TopPodcastsInteractable) {
    self.interactor = interactor
    self.stateStore = TopPodcastsViewStateStore(state: interactor.state)
    super.init(rootView: TopPodcastsView(stateStore: stateStore))
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func present(state: TopPodcastsState) {
    stateStore.state = state
  }
}
