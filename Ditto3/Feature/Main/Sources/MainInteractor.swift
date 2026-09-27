import Discover
import Latest
import Library
import Player
import RIBsLite
import Search

enum MainAction {
  case selectTab(MainTab)
}

@MainActor
protocol MainInteractable: AnyObject, DiscoverListener, LatestListener, LibraryListener, PlayerListener, SearchListener {
  var store: StateStore<MainState> { get }
  func sendAction(_ action: MainAction)
}

@MainActor
final class MainInteractor: Interactor, MainInteractable {
  let store: StateStore<MainState>
  var router: MainRouting?
  weak var listener: MainListener?

  override init() {
    self.store = StateStore(MainState())
    super.init()
  }

  override func didBecomeActive() {
    router?.routeToMain(tab: .discover)
  }

  func playerVisibilityDidChange(_ isVisible: Bool) {
    store.state.isPlayerVisible = isVisible
  }

  func sendAction(_ action: MainAction) {
    switch action {
    case let .selectTab(tab):
      store.state.selectedTab = tab
    }
  }
}
