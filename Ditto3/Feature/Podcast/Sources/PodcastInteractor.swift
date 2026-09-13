import Entity
import Foundation
import Repository
import RIBsLite

enum PodcastAction {
  case retryEpisodes
  case retryFollowing
  case toggleFollowing
  case selectEpisode(Episode)
}

@MainActor
protocol PodcastInteractable: AnyObject {
  var store: StateStore<PodcastState> { get }
  func sendAction(_ action: PodcastAction)
}

@MainActor
final class PodcastInteractor: Interactor, PodcastInteractable {
  private let dependency: PodcastDependency
  private let podcast: Podcast

  let store: StateStore<PodcastState>
  var router: PodcastRouting?
  weak var listener: PodcastListener?

  private var episodeLoadTask: Task<Void, Never>?
  private var followingObservationTask: Task<Void, Never>?
  private var followingMutationTask: Task<Void, Never>?

  init(podcast: Podcast, dependency: PodcastDependency) {
    self.podcast = podcast
    self.dependency = dependency
    self.store = StateStore(PodcastState(podcast: podcast))
  }

  deinit {
    episodeLoadTask?.cancel()
    followingObservationTask?.cancel()
    followingMutationTask?.cancel()
  }

  override func didBecomeActive() {
    loadEpisodes()
    observeFollowing()
  }

  func sendAction(_ action: PodcastAction) {
    switch action {
    case .retryEpisodes:
      loadEpisodes()
    case .retryFollowing:
      observeFollowing()
    case .toggleFollowing:
      toggleFollowing()
    case .selectEpisode(let episode):
      router?.routeToEpisode(episode)
    }
  }

  private func loadEpisodes() {
    episodeLoadTask?.cancel()
    store.state.episodes = .loading

    let podcastRepository = dependency.podcastRepository
    let episodeRepository = dependency.episodeRepository
    let podcast = podcast

    episodeLoadTask = Task { [weak store] in
      do {
        let feedURL = if let feedURL = podcast.feedURL {
          feedURL
        } else {
          try await podcastRepository.resolveFeedURL(podcastID: podcast.id)
        }
        let episodes = try await episodeRepository.fetchEpisodes(
          podcast: podcast,
          feedURL: feedURL,
          limit: 20
        )
        guard !Task.isCancelled, let store else { return }
        store.state.episodes = .loaded(episodes)
      } catch {
        guard !Task.isCancelled, let store else { return }
        store.state.episodes = .failed(message: error.localizedDescription)
      }
    }
  }

  private func observeFollowing() {
    followingObservationTask?.cancel()
    store.state.isFollowing = nil
    store.state.followingErrorMessage = nil

    let repository = dependency.followingRepository
    let podcastID = podcast.id

    followingObservationTask = Task { [weak store] in
      let changes = await repository.changes()
      await Self.reloadFollowing(repository: repository, podcastID: podcastID, store: store)

      for await _ in changes {
        guard !Task.isCancelled else { return }
        await Self.reloadFollowing(repository: repository, podcastID: podcastID, store: store)
      }
    }
  }

  private func toggleFollowing() {
    guard let wasFollowing = store.state.isFollowing,
          !store.state.isUpdatingFollowing else {
      return
    }

    followingMutationTask?.cancel()
    store.state.isFollowing = !wasFollowing
    store.state.isUpdatingFollowing = true
    store.state.followingErrorMessage = nil

    let repository = dependency.followingRepository
    let podcast = podcast

    followingMutationTask = Task { [weak store] in
      do {
        if wasFollowing {
          try await repository.unfollow(podcastID: podcast.id)
        } else {
          try await repository.follow(podcast)
        }
        guard !Task.isCancelled, let store else { return }
        store.state.isUpdatingFollowing = false
      } catch {
        guard !Task.isCancelled, let store else { return }
        store.state.isFollowing = wasFollowing
        store.state.isUpdatingFollowing = false
        store.state.followingErrorMessage = error.localizedDescription
      }
    }
  }

  private static func reloadFollowing(
    repository: FollowingRepository,
    podcastID: PodcastID,
    store: StateStore<PodcastState>?
  ) async {
    do {
      let isFollowing = try await repository.isFollowing(podcastID: podcastID)
      guard !Task.isCancelled, let store else { return }
      store.state.isFollowing = isFollowing
      store.state.followingErrorMessage = nil
    } catch {
      guard !Task.isCancelled, let store else { return }
      store.state.isFollowing = nil
      store.state.followingErrorMessage = error.localizedDescription
    }
  }
}
