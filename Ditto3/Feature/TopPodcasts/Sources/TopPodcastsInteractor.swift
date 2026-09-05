import Combine
import Entity
import Podcast
import Repository
import RIBsLite

enum TopPodcastsAction {
  case retry
  case selectPodcast(Podcast)
}

@MainActor
protocol TopPodcastsInteractable: AnyObject {
  var store: TopPodcastsStateStore { get }
  func sendAction(_ action: TopPodcastsAction)
}

public protocol TopPodcastsDependency {
  var podcastRepository: PodcastRepository { get }
  var podcastBuilder: PodcastBuildable { get }
}

final class TopPodcastsStateStore: ObservableObject {
  @Published fileprivate(set) var state: TopPodcastsState
  init(initialState: TopPodcastsState) { self.state = initialState }
}

@MainActor
final class TopPodcastsInteractor: Interactor, TopPodcastsInteractable {
  private let dependency: TopPodcastsDependency
  let store: TopPodcastsStateStore
  var router: TopPodcastsRouting?
  weak var listener: TopPodcastsListener?
  
  private let limit = 20

  init(dependency: TopPodcastsDependency) {
    self.dependency = dependency
    self.store = TopPodcastsStateStore(initialState: .none)
    super.init()
  }

  override func didBecomeActive() {
    guard case .none = store.state else { return }
    Task {
      await fetchTopPodcasts()
    }
  }

  func sendAction(_ action: TopPodcastsAction) {
    switch action {
    case .retry:
      Task {
        await fetchTopPodcasts()
      }
    case .selectPodcast(let podcast):
      router?.routeToPodcast(podcast)
    }
  }

  private func fetchTopPodcasts() async {
    store.state = .loading
    do {
      let items = try await dependency.podcastRepository.fetchTopPodcasts(limit: limit)
      store.state = .loaded(items)
    } catch {
      store.state = .failed(error)
    }
  }
}
