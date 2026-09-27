import RIBsLite
import SwiftUI
import UIKit

@MainActor
final class LatestViewController: UIHostingController<StateReader<LatestState, LatestView>>, LatestControllable {
  let interactor: LatestInteractable

  init(interactor: LatestInteractable) {
    self.interactor = interactor
    super.init(rootView: StateReader(store: interactor.store) { state in
      LatestView(state: state, sendAction: interactor.sendAction)
    })
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
