import SwiftUI
import UIKit

@MainActor
final class TopPodcastsViewController: UIHostingController<TopPodcastsView>, TopPodcastsControllable {
  private let interactor: TopPodcastsInteractable

  init(interactor: TopPodcastsInteractable) {
    self.interactor = interactor
    super.init(rootView: TopPodcastsView(store: interactor.store, interactor: interactor))
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
