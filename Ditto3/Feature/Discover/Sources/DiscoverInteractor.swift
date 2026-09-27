import Entity
import Podcast
import Repository
import RIBsLite

enum DiscoverAction {
  case viewDidLoad
  case retry
  case selectPodcast(Podcast)
}

@MainActor
protocol DiscoverInteractable: AnyObject {
  var store: StateStore<DiscoverState> { get }
  func sendAction(_ action: DiscoverAction)
}

public protocol DiscoverDependency {
  var podcastRepository: PodcastRepository { get }
  var podcastBuilder: PodcastBuildable { get }
}

@MainActor
final class DiscoverInteractor: Interactor, DiscoverInteractable {
  private let dependency: DiscoverDependency
  let store: StateStore<DiscoverState>
  var router: DiscoverRouting?
  weak var listener: DiscoverListener?
  
  private let limit = 20

  init(dependency: DiscoverDependency) {
    self.dependency = dependency
    self.store = StateStore(.none)
    super.init()
  }

  func sendAction(_ action: DiscoverAction) {
    switch action {
    case .viewDidLoad:
      guard case .none = store.state else { return }
      Task {
        await fetchPodcasts()
      }
    case .retry:
      Task {
        await fetchPodcasts()
      }
    case .selectPodcast(let podcast):
      router?.routeToPodcast(podcast)
    }
  }

  private func fetchPodcasts() async {
    store.state = .loading
    do {
      let items = try await dependency.podcastRepository.fetchTopPodcasts(limit: limit)
      store.state = .loaded(items)
    } catch {
      store.state = .failed(error)
    }
  }
}
