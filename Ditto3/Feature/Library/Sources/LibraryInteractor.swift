import Entity
import Repository
import RIBsLite

enum LibraryAction {
  case retry
  case selectPodcast(Podcast)
}

@MainActor
protocol LibraryInteractable: AnyObject {
  var store: StateStore<LibraryState> { get }
  func sendAction(_ action: LibraryAction)
}

@MainActor
final class LibraryInteractor: Interactor, LibraryInteractable {
  private let dependency: LibraryDependency

  let store = StateStore<LibraryState>(.loading)
  var router: LibraryRouting?
  weak var listener: LibraryListener?

  private var observationTask: Task<Void, Never>?

  init(dependency: LibraryDependency) {
    self.dependency = dependency
  }

  deinit {
    observationTask?.cancel()
  }

  override func didBecomeActive() {
    observeFollowing()
  }

  func sendAction(_ action: LibraryAction) {
    switch action {
    case .retry:
      observeFollowing()
    case .selectPodcast(let podcast):
      router?.routeToPodcast(podcast)
    }
  }

  private func observeFollowing() {
    observationTask?.cancel()
    store.state = .loading

    let repository = dependency.followingRepository
    observationTask = Task { [weak store] in
      let changes = await repository.changes()
      await Self.reload(repository: repository, store: store)

      for await _ in changes {
        guard !Task.isCancelled else { return }
        await Self.reload(repository: repository, store: store)
      }
    }
  }

  private static func reload(
    repository: FollowingRepository,
    store: StateStore<LibraryState>?
  ) async {
    do {
      let followedPodcasts = try await repository.fetchFollowedPodcasts()
      guard !Task.isCancelled, let store else { return }
      store.state = .loaded(followedPodcasts)
    } catch {
      guard !Task.isCancelled, let store else { return }
      store.state = .failed(message: error.localizedDescription)
    }
  }
}
