import Discover
import Entity
import Latest
import Library
import Player
import RIBsLite
import Search

enum MainAction {
  case selectTab(MainTab)
}

@MainActor
protocol MainInteractable: AnyObject {
  var store: StateStore<MainState> { get }
  func sendAction(_ action: MainAction)
}

@MainActor
final class MainInteractor: Interactor, MainInteractable, DiscoverListener, LatestListener, LibraryListener, PlayerListener, SearchListener {
  let store: StateStore<MainState>
  var router: MainRouting?
  weak var listener: MainListener?

  override init() {
    self.store = StateStore(MainState())
    super.init()
  }

  override func didBecomeActive() {
    guard let router else { return }
    router.attachDiscoverTab(listener: self)
    router.attachLatestTab(listener: self)
    router.attachLibraryTab(listener: self)
    router.attachSearchTab(listener: self)
    router.attachPlayer(listener: self)
    router.selectTab(.discover)
  }

  func playerDidRequestEpisode(_ episode: Episode) {
    router?.routeToEpisode(episode)
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
