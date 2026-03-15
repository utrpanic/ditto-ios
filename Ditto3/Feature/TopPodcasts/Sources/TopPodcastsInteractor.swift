import Repository

@MainActor
protocol TopPodcastsPresentable: AnyObject {
  func present(state: TopPodcastsState)
}

@MainActor
protocol TopPodcastsInteractable: AnyObject {
  var state: TopPodcastsState { get }
}

public protocol TopPodcastsDependency {
  var podcastRepository: PodcastRepository { get }
}

@MainActor
final class TopPodcastsInteractor: TopPodcastsInteractable {
  private(set) var state = TopPodcastsState()
  private let dependency: TopPodcastsDependency
  weak var presenter: TopPodcastsPresentable?
  weak var listener: TopPodcastsListener?

  init(dependency: TopPodcastsDependency) {
    self.dependency = dependency
    Task {
      await fetchTopPodcasts()
    }
  }

  private func fetchTopPodcasts() async {
    updateState {
      $0.isLoading = true
      $0.errorMessage = nil
    }

    do {
      let items = try await dependency.podcastRepository.fetchTopPodcasts(limit: state.limit)
      updateState {
        $0.items = items
      }
    } catch {
      updateState {
        $0.items = []
        $0.errorMessage = "Failed to load top podcasts."
      }
    }

    updateState {
      $0.isLoading = false
    }
  }

  private func updateState(_ update: (inout TopPodcastsState) -> Void) {
    update(&state)
    presenter?.present(state: state)
  }
}
