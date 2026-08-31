import SwiftUI
import UIKit

@MainActor
final class EpisodeViewController: UIHostingController<EpisodeView>, EpisodeControllable {
  let interactor: EpisodeInteractable

  init(interactor: EpisodeInteractable) {
    self.interactor = interactor
    super.init(rootView: EpisodeView(store: interactor.store))
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
