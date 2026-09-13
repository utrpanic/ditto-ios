import Entity
import Episode
import Foundation
import Repository
import RIBsLite
@testable import Podcast
import Testing
import UIKit

struct PodcastTests {
  @MainActor
  @Test
  func buildPassesPodcastAndListenerToRIB() throws {
    let podcast = makePodcast()
    let listener = Listener()
    let builder = PodcastBuilder(dependency: Dependency())

    let result = builder.build(podcast: podcast, listener: listener)

    let viewController = try #require(result as? PodcastViewController)
    let interactor = try #require(viewController.interactor as? PodcastInteractor)
    #expect(interactor.store.state.podcast == podcast)
    #expect(interactor.listener === listener)
    #expect(interactor.router != nil)
  }

  @MainActor
  @Test
  func selectingEpisodeRoutesToEpisode() {
    let interactor = PodcastInteractor(podcast: makePodcast(), dependency: Dependency())
    let router = RouterSpy()
    let episode = makeEpisode()
    interactor.router = router

    interactor.sendAction(.selectEpisode(episode))

    #expect(router.routedEpisode == episode)
  }

  @MainActor
  @Test
  func routerBuildsAndPushesSelectedEpisode() {
    let episode = makeEpisode()
    let destination = UIViewController()
    let episodeBuilder = EpisodeBuilderSpy(destination: destination)
    let dependency = Dependency(episodeBuilder: episodeBuilder)
    let podcastViewController = PodcastViewControllerStub()
    let navigationController = UINavigationController(rootViewController: podcastViewController)
    let router = PodcastRouter(dependency: dependency, viewController: podcastViewController)

    router.routeToEpisode(episode)

    #expect(episodeBuilder.builtEpisode == episode)
    #expect(navigationController.topViewController === destination)
  }

  @MainActor
  @Test
  func activationLoadsFollowingState() async {
    let podcast = makePodcast()
    let followingRepository = FollowingRepositorySpy(followedPodcasts: [podcast])
    let dependency = Dependency(followingRepository: followingRepository)
    let interactor = PodcastInteractor(podcast: podcast, dependency: dependency)

    interactor.activate()
    await waitUntil { interactor.store.state.isFollowing == true }

    #expect(interactor.store.state.isFollowing == true)
  }

  @MainActor
  @Test
  func followingPodcastUpdatesOptimisticallyAndPersists() async {
    let podcast = makePodcast()
    let followingRepository = FollowingRepositorySpy()
    let dependency = Dependency(followingRepository: followingRepository)
    let interactor = PodcastInteractor(podcast: podcast, dependency: dependency)
    interactor.activate()
    await waitUntil { interactor.store.state.isFollowing == false }

    interactor.sendAction(.toggleFollowing)

    #expect(interactor.store.state.isFollowing == true)
    #expect(interactor.store.state.isUpdatingFollowing)
    await waitUntil { !interactor.store.state.isUpdatingFollowing }
    #expect(await followingRepository.isFollowing(podcastID: podcast.id))
  }

  @MainActor
  @Test
  func failedFollowingUpdateRollsBackOptimisticState() async {
    let podcast = makePodcast()
    let followingRepository = FollowingRepositorySpy(shouldFailMutation: true)
    let dependency = Dependency(followingRepository: followingRepository)
    let interactor = PodcastInteractor(podcast: podcast, dependency: dependency)
    interactor.activate()
    await waitUntil { interactor.store.state.isFollowing == false }

    interactor.sendAction(.toggleFollowing)
    await waitUntil { !interactor.store.state.isUpdatingFollowing }

    #expect(interactor.store.state.isFollowing == false)
    #expect(interactor.store.state.followingErrorMessage != nil)
  }

  @MainActor
  @Test
  func repositoryChangesSynchronizeActivePodcastEntryPoints() async throws {
    let podcast = makePodcast()
    let followingRepository = FollowingRepositorySpy()
    let dependency = Dependency(followingRepository: followingRepository)
    let firstInteractor = PodcastInteractor(podcast: podcast, dependency: dependency)
    let secondInteractor = PodcastInteractor(podcast: podcast, dependency: dependency)
    firstInteractor.activate()
    secondInteractor.activate()
    await waitUntil {
      firstInteractor.store.state.isFollowing == false
        && secondInteractor.store.state.isFollowing == false
    }

    try await followingRepository.follow(podcast)
    await waitUntil {
      firstInteractor.store.state.isFollowing == true
        && secondInteractor.store.state.isFollowing == true
    }

    #expect(firstInteractor.store.state.isFollowing == true)
    #expect(secondInteractor.store.state.isFollowing == true)
  }
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async {
  for _ in 0..<1_000 {
    guard !condition() else { return }
    await Task.yield()
  }
}

private func makePodcast() -> Podcast {
  Podcast(
    id: PodcastID(42),
    title: "Architecture Talks",
    author: "Ditto",
    feedURL: URL(string: "https://example.com/feed.xml")
  )
}

private func makeEpisode() -> Episode {
  Episode(
    id: EpisodeID("episode-guid"),
    podcastID: PodcastID(42),
    podcastTitle: "Architecture Talks",
    title: "View-controller-centered RIBs",
    feedURL: URL(string: "https://example.com/feed.xml")!
  )
}

private struct Dependency: PodcastDependency {
  let podcastRepository: PodcastRepository = PodcastRepositoryStub()
  let episodeRepository: EpisodeRepository = EpisodeRepositoryStub()
  let followingRepository: FollowingRepository
  let episodeBuilder: EpisodeBuildable

  @MainActor
  init(
    followingRepository: FollowingRepository = FollowingRepositorySpy(),
    episodeBuilder: EpisodeBuildable? = nil
  ) {
    self.followingRepository = followingRepository
    self.episodeBuilder = episodeBuilder ?? EpisodeBuilderStub()
  }
}

private actor FollowingRepositorySpy: FollowingRepository {
  private var followedPodcasts: [FollowedPodcast]
  private let shouldFailMutation: Bool
  private var changeContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]

  init(
    followedPodcasts: [Podcast] = [],
    shouldFailMutation: Bool = false
  ) {
    self.followedPodcasts = followedPodcasts.map {
      FollowedPodcast(podcast: $0, followedAt: Date())
    }
    self.shouldFailMutation = shouldFailMutation
  }

  func fetchFollowedPodcasts() -> [FollowedPodcast] {
    followedPodcasts
  }

  func isFollowing(podcastID: PodcastID) -> Bool {
    followedPodcasts.contains { $0.podcast.id == podcastID }
  }

  func follow(_ podcast: Podcast) throws {
    if shouldFailMutation { throw FollowingError.failed }
    guard !followedPodcasts.contains(where: { $0.podcast.id == podcast.id }) else { return }
    followedPodcasts.append(FollowedPodcast(podcast: podcast, followedAt: Date()))
    notifyChanges()
  }

  func unfollow(podcastID: PodcastID) throws {
    if shouldFailMutation { throw FollowingError.failed }
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

private enum FollowingError: LocalizedError {
  case failed

  var errorDescription: String? {
    "Failed to update following state."
  }
}

private struct PodcastRepositoryStub: PodcastRepository {
  func fetchTopPodcasts(limit: Int) async throws -> [Podcast] { [] }
  func searchPodcasts(query: String) async throws -> [Podcast] { [] }
  func resolveFeedURL(podcastID: PodcastID) async throws -> URL {
    URL(string: "https://example.com/feed.xml")!
  }
}

private struct EpisodeRepositoryStub: EpisodeRepository {
  func searchEpisodes(query: String) async throws -> [Episode] { [] }
  func fetchEpisodes(podcast: Podcast, feedURL: URL, limit: Int?) async throws -> [Episode] { [] }
}

@MainActor
private final class Listener: PodcastListener {}

@MainActor
private final class RouterSpy: PodcastRouting {
  private(set) var routedEpisode: Episode?

  func routeToEpisode(_ episode: Episode) {
    routedEpisode = episode
  }
}

@MainActor
private final class EpisodeBuilderStub: EpisodeBuildable {
  func build(episode: Episode, listener: EpisodeListener?) -> ViewControllable {
    UIViewController()
  }
}

@MainActor
private final class EpisodeBuilderSpy: EpisodeBuildable {
  private let destination: ViewControllable
  private(set) var builtEpisode: Episode?

  init(destination: ViewControllable) {
    self.destination = destination
  }

  func build(episode: Episode, listener: EpisodeListener?) -> ViewControllable {
    builtEpisode = episode
    return destination
  }
}

@MainActor
private final class PodcastViewControllerStub: UIViewController, PodcastControllable {}
