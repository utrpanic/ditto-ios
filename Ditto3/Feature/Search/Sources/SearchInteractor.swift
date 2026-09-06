import Entity
import Repository
import RIBsLite

enum SearchAction {
  case search(String)
  case clear
  case selectPodcast(Podcast)
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
    self.store = StateStore(.idle)
    super.init()
  }

  func sendAction(_ action: SearchAction) {
    switch action {
    case .search(let query):
      search(query: query)
    case .clear:
      searchTask?.cancel()
      store.state = .idle
    case .selectPodcast(let podcast):
      router?.routeToPodcast(podcast)
    }
  }

  private func search(query: String) {
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuery.isEmpty else {
      searchTask?.cancel()
      store.state = .idle
      return
    }

    searchTask?.cancel()
    searchTask = Task { [dependency, weak store] in
      store?.state = .loading(query: trimmedQuery)
      do {
        let podcasts = try await dependency.podcastRepository.searchPodcasts(query: trimmedQuery)
        guard !Task.isCancelled else { return }
        store?.state = .loaded(query: trimmedQuery, podcasts: podcasts)
      } catch {
        guard !Task.isCancelled else { return }
        store?.state = .failed(query: trimmedQuery, message: error.localizedDescription)
      }
    }
  }
}
