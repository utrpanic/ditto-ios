import Entity
import Episode
import Foundation
import Repository
import RIBsLite
@testable import Latest
import Testing
import UIKit

struct LatestTests {
  @MainActor
  @Test
  func builderConnectsLatestRIB() throws {
    let listener = Listener()
    let builder = LatestBuilder(dependency: Dependency())

    let result = builder.build(listener: listener)

    let viewController = try #require(result as? LatestViewController)
    let interactor = try #require(viewController.interactor as? LatestInteractor)
    #expect(interactor.listener === listener)
    #expect(interactor.router != nil)
  }

  @MainActor
  @Test
  func aggregatesConcurrentlyDeduplicatesSortsAndLimitsEpisodes() async {
    let firstPodcast = makePodcast(id: 1)
    let secondPodcast = makePodcast(id: 2)
    let firstEpisodes = (0..<15).map { makeEpisode(index: $0, podcast: firstPodcast) }
    let secondEpisodes = (10..<25).map { makeEpisode(index: $0, podcast: secondPodcast) }
    let episodeRepository = EpisodeRepositorySpy(
      episodesByPodcastID: [
        firstPodcast.id: firstEpisodes,
        secondPodcast.id: secondEpisodes,
      ]
    )
    let dependency = Dependency(
      followingRepository: FollowingRepositorySpy(podcasts: [firstPodcast, secondPodcast]),
      episodeRepository: episodeRepository
    )
    let interactor = LatestInteractor(dependency: dependency)

    interactor.activate()
    await waitUntil {
      guard case .loaded = interactor.store.state else { return false }
      return true
    }

    guard case .loaded(let episodes, let failedPodcastCount) = interactor.store.state else {
      Issue.record("Expected a loaded latest state.")
      return
    }
    #expect(episodes.count == 20)
    #expect(episodes.map(\.id.value) == (5..<25).reversed().map { "episode-\($0)" })
    #expect(Set(episodes.map(\.id)).count == episodes.count)
    #expect(failedPodcastCount == 0)
    #expect(await episodeRepository.maximumConcurrentFetchCount() == 2)
  }

  @MainActor
  @Test
  func partialFailureKeepsSuccessfulEpisodes() async {
    let successfulPodcast = makePodcast(id: 1)
    let failedPodcast = makePodcast(id: 2)
    let episode = makeEpisode(index: 1, podcast: successfulPodcast)
    let episodeRepository = EpisodeRepositorySpy(
      episodesByPodcastID: [successfulPodcast.id: [episode]],
      failingPodcastIDs: [failedPodcast.id]
    )
    let dependency = Dependency(
      followingRepository: FollowingRepositorySpy(podcasts: [successfulPodcast, failedPodcast]),
      episodeRepository: episodeRepository
    )
    let interactor = LatestInteractor(dependency: dependency)

    interactor.activate()
    await waitUntil {
      interactor.store.state == .loaded(episodes: [episode], failedPodcastCount: 1)
    }

    #expect(interactor.store.state == .loaded(episodes: [episode], failedPodcastCount: 1))
  }

  @MainActor
  @Test
  func allFeedFailuresProduceFailureState() async {
    let podcasts = [makePodcast(id: 1), makePodcast(id: 2)]
    let dependency = Dependency(
      followingRepository: FollowingRepositorySpy(podcasts: podcasts),
      episodeRepository: EpisodeRepositorySpy(failingPodcastIDs: Set(podcasts.map(\.id)))
    )
    let interactor = LatestInteractor(dependency: dependency)

    interactor.activate()
    await waitUntil {
      guard case .failed = interactor.store.state else { return false }
      return true
    }

    guard case .failed = interactor.store.state else {
      Issue.record("Expected a failed latest state.")
      return
    }
  }

  @MainActor
  @Test
  func followingChangesRefreshLatestEpisodes() async {
    let podcast = makePodcast(id: 1)
    let episode = makeEpisode(index: 1, podcast: podcast)
    let followingRepository = FollowingRepositorySpy()
    let dependency = Dependency(
      followingRepository: followingRepository,
      episodeRepository: EpisodeRepositorySpy(episodesByPodcastID: [podcast.id: [episode]])
    )
    let interactor = LatestInteractor(dependency: dependency)
    interactor.activate()
    await waitUntil {
      interactor.store.state == .loaded(episodes: [], failedPodcastCount: 0)
    }

    await followingRepository.follow(podcast)
    await waitUntil {
      interactor.store.state == .loaded(episodes: [episode], failedPodcastCount: 0)
    }

    #expect(interactor.store.state == .loaded(episodes: [episode], failedPodcastCount: 0))
  }

  @MainActor
  @Test
  func selectingEpisodeRoutesToEpisode() {
    let podcast = makePodcast(id: 1)
    let episode = makeEpisode(index: 1, podcast: podcast)
    let interactor = LatestInteractor(dependency: Dependency())
    let router = RouterSpy()
    interactor.router = router

    interactor.sendAction(.selectEpisode(episode))

    #expect(router.routedEpisode == episode)
  }

  @MainActor
  @Test
  func routerBuildsAndPushesSelectedEpisode() {
    let episode = makeEpisode(index: 1, podcast: makePodcast(id: 1))
    let destination = UIViewController()
    let episodeBuilder = EpisodeBuilderSpy(destination: destination)
    let dependency = Dependency(episodeBuilder: episodeBuilder)
    let latestViewController = LatestViewControllerStub()
    let navigationController = UINavigationController(rootViewController: latestViewController)
    let router = LatestRouter(dependency: dependency, viewController: latestViewController)

    router.routeToEpisode(episode)

    #expect(episodeBuilder.builtEpisode == episode)
    #expect(navigationController.topViewController === destination)
  }
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async {
  for _ in 0..<1_000 {
    guard !condition() else { return }
    try? await Task.sleep(nanoseconds: 1_000_000)
  }
}

private func makePodcast(id: Int) -> Podcast {
  Podcast(
    id: PodcastID(id),
    title: "Podcast \(id)",
    author: "Ditto",
    feedURL: URL(string: "https://example.com/feed-\(id).xml")!
  )
}

private func makeEpisode(index: Int, podcast: Podcast) -> Entity.Episode {
  Entity.Episode(
    id: EpisodeID("episode-\(index)"),
    podcastID: podcast.id,
    podcastTitle: podcast.title,
    title: "Episode \(index)",
    feedURL: podcast.feedURL!,
    publishedAt: Date(timeIntervalSince1970: TimeInterval(index))
  )
}

private struct Dependency: LatestDependency {
  let followingRepository: FollowingRepository
  let podcastRepository: PodcastRepository
  let episodeRepository: EpisodeRepository
  let episodeBuilder: EpisodeBuildable

  @MainActor
  init(
    followingRepository: FollowingRepository = FollowingRepositorySpy(),
    podcastRepository: PodcastRepository = PodcastRepositoryStub(),
    episodeRepository: EpisodeRepository = EpisodeRepositorySpy(),
    episodeBuilder: EpisodeBuildable? = nil
  ) {
    self.followingRepository = followingRepository
    self.podcastRepository = podcastRepository
    self.episodeRepository = episodeRepository
    self.episodeBuilder = episodeBuilder ?? EpisodeBuilderStub()
  }
}

private actor FollowingRepositorySpy: FollowingRepository {
  private var followedPodcasts: [FollowedPodcast]
  private var changeContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]

  init(podcasts: [Podcast] = []) {
    self.followedPodcasts = podcasts.map {
      FollowedPodcast(podcast: $0, followedAt: Date())
    }
  }

  func fetchFollowedPodcasts() -> [FollowedPodcast] {
    followedPodcasts
  }

  func isFollowing(podcastID: PodcastID) -> Bool {
    followedPodcasts.contains { $0.podcast.id == podcastID }
  }

  func follow(_ podcast: Podcast) {
    guard !followedPodcasts.contains(where: { $0.podcast.id == podcast.id }) else { return }
    followedPodcasts.append(FollowedPodcast(podcast: podcast, followedAt: Date()))
    notifyChanges()
  }

  func unfollow(podcastID: PodcastID) {
    followedPodcasts.removeAll { $0.podcast.id == podcastID }
    notifyChanges()
  }

  func changes() -> AsyncStream<Void> {
    let id = UUID()
    let (stream, continuation) = AsyncStream<Void>.makeStream()
    changeContinuations[id] = continuation
    return stream
  }

  private func notifyChanges() {
    for continuation in changeContinuations.values {
      continuation.yield(())
    }
  }
}

private struct PodcastRepositoryStub: PodcastRepository {
  func fetchTopPodcasts(limit: Int) async throws -> [Podcast] { [] }
  func searchPodcasts(query: String) async throws -> [Podcast] { [] }
  func resolveFeedURL(podcastID: PodcastID) async throws -> URL {
    URL(string: "https://example.com/feed-\(podcastID.value).xml")!
  }
}

private actor EpisodeRepositorySpy: EpisodeRepository {
  private let episodesByPodcastID: [PodcastID: [Entity.Episode]]
  private let failingPodcastIDs: Set<PodcastID>
  private var activeFetchCount = 0
  private var maximumActiveFetchCount = 0

  init(
    episodesByPodcastID: [PodcastID: [Entity.Episode]] = [:],
    failingPodcastIDs: Set<PodcastID> = []
  ) {
    self.episodesByPodcastID = episodesByPodcastID
    self.failingPodcastIDs = failingPodcastIDs
  }

  func searchEpisodes(query: String) -> [Entity.Episode] { [] }

  func fetchEpisodes(
    podcast: Podcast,
    feedURL: URL,
    limit: Int?
  ) async throws -> [Entity.Episode] {
    activeFetchCount += 1
    maximumActiveFetchCount = max(maximumActiveFetchCount, activeFetchCount)
    defer { activeFetchCount -= 1 }
    try await Task.sleep(nanoseconds: 5_000_000)

    if failingPodcastIDs.contains(podcast.id) {
      throw RepositoryError.failed
    }
    return episodesByPodcastID[podcast.id] ?? []
  }

  func maximumConcurrentFetchCount() -> Int {
    maximumActiveFetchCount
  }
}

private enum RepositoryError: Error {
  case failed
}

@MainActor
private final class Listener: LatestListener {}

@MainActor
private final class RouterSpy: LatestRouting {
  private(set) var routedEpisode: Entity.Episode?

  func routeToEpisode(_ episode: Entity.Episode) {
    routedEpisode = episode
  }
}

@MainActor
private final class EpisodeBuilderStub: EpisodeBuildable {
  func build(episode: Entity.Episode, listener: EpisodeListener?) -> ViewControllable {
    UIViewController()
  }
}

@MainActor
private final class EpisodeBuilderSpy: EpisodeBuildable {
  private let destination: ViewControllable
  private(set) var builtEpisode: Entity.Episode?

  init(destination: ViewControllable) {
    self.destination = destination
  }

  func build(episode: Entity.Episode, listener: EpisodeListener?) -> ViewControllable {
    builtEpisode = episode
    return destination
  }
}

@MainActor
private final class LatestViewControllerStub: UIViewController, LatestControllable {}
