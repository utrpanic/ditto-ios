import Entity
import Episode
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
}

private func makePodcast() -> Podcast {
  Podcast(
    id: PodcastID(42),
    title: "Architecture Talks",
    author: "KeepCast",
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
  let episodeBuilder: EpisodeBuildable

  @MainActor
  init(episodeBuilder: EpisodeBuildable? = nil) {
    self.episodeBuilder = episodeBuilder ?? EpisodeBuilderStub()
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
