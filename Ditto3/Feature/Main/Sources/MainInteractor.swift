import TopPodcasts
import New
import Bookmarks
import Search
import RIBsLite

enum MainAction {
  case selectTab(MainTab)
}

@MainActor
final class MainInteractor: Interactor, MainInteractable, TopPodcastsListener, NewListener, BookmarksListener, SearchListener {
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
    router?.attachTopPodcasts(listener: self)
    router?.attachNew(listener: self)
    router?.attachBookmarks(listener: self)
    router?.attachSearch(listener: self)
  }

  func sendAction(_ action: MainAction) {
    switch action {
    case let .selectTab(tab):
      store.state.selectedTab = tab
    }
  }
}
