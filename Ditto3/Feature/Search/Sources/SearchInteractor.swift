import Entity
import Repository
import RIBsLite

enum SearchAction {
  case updateQuery(String)
  case submitSearch
  case selectTab(SearchTab)
  case selectPodcast(Podcast)
  case selectEpisode(Episode)
}

@MainActor
protocol SearchInteractable: AnyObject {
  var store: StateStore<SearchState> { get }
  func sendAction(_ action: SearchAction)
}

@MainActor
final class SearchInteractor: Interactor, SearchInteractable {
  private let dependency: SearchDependency
  let store: StateStore<SearchState>
  var router: SearchRouting?
  weak var listener: SearchListener?

  private var searchTask: Task<Void, Never>?

  init(dependency: SearchDependency) {
    self.dependency = dependency
    self.store = StateStore(SearchState())
    super.init()
  }

  func sendAction(_ action: SearchAction) {
    switch action {
    case .updateQuery(let query):
      updateQuery(query)
    case .submitSearch:
      search()
    case .selectTab(let tab):
      selectTab(tab)
    case .selectPodcast(let podcast):
      router?.routeToPodcast(podcast)
    case .selectEpisode(let episode):
      router?.routeToEpisode(episode)
    }
  }

  private func updateQuery(_ query: String) {
    guard store.state.query != query else { return }
    searchTask?.cancel()
    var state = store.state
    state.query = query
    state.result = .idle
    store.state = state
  }

  private func selectTab(_ tab: SearchTab) {
    guard store.state.selectedTab != tab else { return }
    searchTask?.cancel()
    var state = store.state
    state.selectedTab = tab
    state.result = .idle
    store.state = state
    search()
  }

  private func search() {
    let query = store.state.query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else {
      searchTask?.cancel()
      var state = store.state
      state.result = .idle
      store.state = state
      return
    }

    let tab = store.state.selectedTab
    searchTask?.cancel()
    var state = store.state
    state.result = .loading(query: query)
    store.state = state
    searchTask = Task { [dependency, weak store] in
      do {
        let result: SearchResultState = switch tab {
        case .podcast:
          .podcasts(try await dependency.podcastRepository.searchPodcasts(query: query))
        case .episode:
          .episodes(try await dependency.episodeRepository.searchEpisodes(query: query))
        }
        guard !Task.isCancelled else { return }
        guard let store else { return }
        var state = store.state
        state.result = result
        store.state = state
      } catch {
        guard !Task.isCancelled else { return }
        guard let store else { return }
        var state = store.state
        state.result = .failed(query: query, message: error.localizedDescription)
        store.state = state
      }
    }
  }
}
