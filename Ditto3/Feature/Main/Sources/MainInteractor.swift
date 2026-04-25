import Combine
import TopPodcasts
import New
import Bookmarks
import Search
import RIBsLite

enum MainAction {
  case selectTab(MainTab)
}

final class MainStateStore: ObservableObject {
  @Published fileprivate(set) var state: MainState
  init(initialState: MainState) { self.state = initialState }
}

@MainActor
final class MainInteractor: Interactor, MainInteractable, TopPodcastsListener, NewListener, BookmarksListener, SearchListener {
  private let dependency: MainDependency
  let store: MainStateStore
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

  func sendAction(_ action: MainAction) {
    switch action {
    case let .selectTab(tab):
      store.state.selectedTab = tab
    }
  }
}
