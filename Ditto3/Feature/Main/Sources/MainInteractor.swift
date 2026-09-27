import Discover
import Entity
import Latest
import Library
import Player
import RIBsLite
import Search

enum MainAction {
  case viewDidLoad
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
  var router: MainRouting? {
    didSet {
      routeToInitialTabIfNeeded()
    }
  }
  private var needsInitialRouting = false
  weak var listener: MainListener?

  override init() {
    self.store = StateStore(MainState())
    super.init()
  }

  private func routeToInitialTabIfNeeded() {
    // UITabBarController can load its view before the builder connects the router.
    guard needsInitialRouting, let router else { return }
    needsInitialRouting = false
    router.routeToMain(tab: .discover)
  }

  func playerDidRequestEpisode(_ episode: Episode) {
    router?.routeToEpisode(episode)
  }

  func playerVisibilityDidChange(_ isVisible: Bool) {
    store.state.isPlayerVisible = isVisible
  }

  func sendAction(_ action: MainAction) {
    switch action {
    case .viewDidLoad:
      needsInitialRouting = true
      routeToInitialTabIfNeeded()
    case let .selectTab(tab):
      store.state.selectedTab = tab
    }
  }
}
