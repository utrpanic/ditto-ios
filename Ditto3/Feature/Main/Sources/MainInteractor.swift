import Discover
import Latest
import Library
import RIBsLite
import Search

enum MainAction {
  case selectTab(MainTab)
}

@MainActor
final class MainInteractor: Interactor, MainInteractable, DiscoverListener, LatestListener, LibraryListener, SearchListener {
  private let dependency: MainDependency
  let store: StateStore<MainState>
  var router: MainRouting?
  weak var listener: MainListener?

  init(dependency: MainDependency) {
    self.dependency = dependency
    self.store = StateStore(MainState())
    super.init()
  }

  override func didBecomeActive() {
    router?.attachDiscover(listener: self)
    router?.attachLatest(listener: self)
    router?.attachLibrary(listener: self)
    router?.attachSearch(listener: self)
  }

  func sendAction(_ action: MainAction) {
    switch action {
    case let .selectTab(tab):
      store.state.selectedTab = tab
    }
  }
}
