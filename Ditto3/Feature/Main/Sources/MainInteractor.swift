import Combine
import TopPodcasts
import New
import Bookmarks
import Search
import RIBsLite

@MainActor
protocol MainPresentableListener: AnyObject {
  func didSelectTab(_ tab: MainTab)
}

@MainActor
final class MainStateStore: ObservableObject {
  @Published fileprivate(set) var state: MainState
  init(initialState: MainState) { self.state = initialState }
}

@MainActor
final class MainInteractor: Interactor, MainInteractable, MainPresentableListener, TopPodcastsListener, NewListener, BookmarksListener, SearchListener {
  private let dependency: MainDependency
  let store: MainStateStore
  private var state: MainState { store.state }
  var router: MainRouting?
  weak var listener: MainListener?

  init(dependency: MainDependency) {
    self.dependency = dependency
    self.store = MainStateStore(initialState: MainState())
    super.init()
  }

  override func didBecomeActive() {
    router?.attachTopPodcasts(listener: self)
    router?.attachNew(listener: self)
    router?.attachBookmarks(listener: self)
    router?.attachSearch(listener: self)
  }

  func didSelectTab(_ tab: MainTab) {
    store.state.selectedTab = tab
  }
}
