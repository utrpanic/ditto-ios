import Repository

@MainActor
protocol TopPodcastsPresentable: AnyObject {
  func present(state: TopPodcastsState)
}

@MainActor
protocol TopPodcastsInteractable: AnyObject {
  var state: TopPodcastsState { get }
  func presentableDidLoad()
}

public protocol TopPodcastsDependency {
  var podcastRepository: PodcastRepository { get }
}

@MainActor
final class TopPodcastsInteractor: TopPodcastsInteractable {
  private(set) var state: TopPodcastsState = .none
  private let dependency: TopPodcastsDependency
  private let limit = 20
  weak var presenter: TopPodcastsPresentable?
  weak var listener: TopPodcastsListener?

  init(dependency: TopPodcastsDependency) {
    self.dependency = dependency
  }

  func presentableDidLoad() {
    Task {
      await fetchTopPodcasts()
    }
  }

  private func fetchTopPodcasts() async {
    updateState(.loading)

    do {
      let items = try await dependency.podcastRepository.fetchTopPodcasts(limit: limit)
      updateState(.loaded(items))
    } catch {
      updateState(.failed(error))
    }
  }

  private func updateState(_ newState: TopPodcastsState) {
    state = newState
    presenter?.present(state: state)
  }
}
