import Entity
import Foundation
import Repository
import RIBsLite
import UIKit

enum LatestAction {
  case refresh
  case selectEpisode(Episode)
}

@MainActor
protocol LatestInteractable: AnyObject {
  var store: StateStore<LatestState> { get }
  func sendAction(_ action: LatestAction)
}

@MainActor
final class LatestInteractor: Interactor, LatestInteractable {
  private let dependency: LatestDependency

  let store = StateStore<LatestState>(.loading)
  var router: LatestRouting?
  weak var listener: LatestListener?

  private var followingObservationTask: Task<Void, Never>?
  private var foregroundObservationTask: Task<Void, Never>?
  private var reloadTask: Task<Void, Never>?

  init(dependency: LatestDependency) {
    self.dependency = dependency
  }

  deinit {
    followingObservationTask?.cancel()
    foregroundObservationTask?.cancel()
    reloadTask?.cancel()
  }

  override func didBecomeActive() {
    observeFollowing()
    observeForegroundEntry()
  }

  func sendAction(_ action: LatestAction) {
    switch action {
    case .refresh:
      reload()
    case .selectEpisode(let episode):
      router?.routeToEpisode(episode)
    }
  }

  private func observeFollowing() {
    followingObservationTask?.cancel()
    let repository = dependency.followingRepository

    followingObservationTask = Task { [weak self] in
      let changes = await repository.changes()
      self?.reload()

      for await _ in changes {
        guard !Task.isCancelled else { return }
        self?.reload()
      }
    }
  }

  private func observeForegroundEntry() {
    foregroundObservationTask?.cancel()
    foregroundObservationTask = Task { [weak self] in
      for await _ in NotificationCenter.default.notifications(
        named: UIApplication.willEnterForegroundNotification
      ) {
        guard !Task.isCancelled else { return }
        self?.reload()
      }
    }
  }

  private func reload() {
    reloadTask?.cancel()
    store.state = .loading

    let followingRepository = dependency.followingRepository
    let podcastRepository = dependency.podcastRepository
    let episodeRepository = dependency.episodeRepository

    reloadTask = Task { [weak store] in
      do {
        let followedPodcasts = try await followingRepository.fetchFollowedPodcasts()
        guard !Task.isCancelled else { return }

        if followedPodcasts.isEmpty {
          store?.state = .loaded(episodes: [], failedPodcastCount: 0)
          return
        }

        let aggregation = await Self.fetchEpisodes(
          for: followedPodcasts.map(\.podcast),
          podcastRepository: podcastRepository,
          episodeRepository: episodeRepository
        )
        guard !Task.isCancelled, let store else { return }

        if aggregation.successCount == 0 {
          store.state = .failed(message: "Unable to load episodes from followed podcasts.")
        } else {
          store.state = .loaded(
            episodes: Self.merge(aggregation.episodes),
            failedPodcastCount: aggregation.failureCount
          )
        }
      } catch {
        guard !Task.isCancelled, let store else { return }
        store.state = .failed(message: error.localizedDescription)
      }
    }
  }

  private static func fetchEpisodes(
    for podcasts: [Podcast],
    podcastRepository: PodcastRepository,
    episodeRepository: EpisodeRepository
  ) async -> Aggregation {
    await withTaskGroup(of: PodcastFetchResult.self) { group in
      for podcast in podcasts {
        group.addTask {
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
            return .success(episodes)
          } catch {
            return .failure
          }
        }
      }

      var aggregation = Aggregation()
      for await result in group {
        switch result {
        case .success(let episodes):
          aggregation.episodes.append(contentsOf: episodes)
          aggregation.successCount += 1
        case .failure:
          aggregation.failureCount += 1
        }
      }
      return aggregation
    }
  }

  private static func merge(_ episodes: [Episode]) -> [Episode] {
    var seenIDs = Set<EpisodeID>()
    return episodes
      .filter { seenIDs.insert($0.id).inserted }
      .sorted { lhs, rhs in
        switch (lhs.publishedAt, rhs.publishedAt) {
        case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
          return lhsDate > rhsDate
        case (_?, nil):
          return true
        case (nil, _?):
          return false
        default:
          return lhs.id.value < rhs.id.value
        }
      }
      .prefix(20)
      .map { $0 }
  }
}

private struct Aggregation {
  var episodes: [Episode] = []
  var successCount = 0
  var failureCount = 0
}

private enum PodcastFetchResult: Sendable {
  case success([Episode])
  case failure
}
