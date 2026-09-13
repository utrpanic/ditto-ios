import Entity
import Episode
import Podcast
import Repository
import RIBsLite
@testable import Search
import Testing
import UIKit

struct SearchTests {
  @MainActor
  @Test
  func selectingTabUpdatesSearchScope() {
    let interactor = SearchInteractor(dependency: Dependency())

    interactor.sendAction(.selectTab(.episode))

    #expect(interactor.store.state.selectedTab == .episode)
    #expect(interactor.store.state.result == .idle)
  }

  @MainActor
  @Test
  func selectingTabSearchesWithSharedQuery() {
    let interactor = SearchInteractor(dependency: Dependency())
    interactor.sendAction(.updateQuery("swift architecture"))

    interactor.sendAction(.selectTab(.episode))

    #expect(interactor.store.state.selectedTab == .episode)
    #expect(interactor.store.state.query == "swift architecture")
    #expect(interactor.store.state.result == .loading(query: "swift architecture"))
  }

  @MainActor
  @Test
  func selectingPodcastRoutesToPodcast() {
    let podcast = Podcast(
      id: PodcastID(42),
      title: "Architecture Talks",
      author: "Ditto"
    )
    let interactor = SearchInteractor(dependency: Dependency())
    let router = RouterSpy()
    interactor.router = router

    interactor.sendAction(.selectPodcast(podcast))

    #expect(router.routedPodcast == podcast)
  }

  @MainActor
  @Test
  func selectingEpisodeRoutesToEpisode() {
    let episode = makeEpisode()
    let interactor = SearchInteractor(dependency: Dependency())
    let router = RouterSpy()
    interactor.router = router

    interactor.sendAction(.selectEpisode(episode))

    #expect(router.routedEpisode == episode)
  }

  @MainActor
  @Test
  func routerBuildsAndPushesSelectedPodcast() {
    let podcast = Podcast(
      id: PodcastID(42),
      title: "Architecture Talks",
      author: "Ditto"
    )
    let destination = UIViewController()
    let podcastBuilder = PodcastBuilderSpy(destination: destination)
    let dependency = Dependency(podcastBuilder: podcastBuilder)
    let searchViewController = SearchViewControllerStub()
    let navigationController = UINavigationController(rootViewController: searchViewController)
    let router = SearchRouter(dependency: dependency, viewController: searchViewController)

    router.routeToPodcast(podcast)

    #expect(podcastBuilder.builtPodcast == podcast)
    #expect(navigationController.topViewController === destination)
  }

  @MainActor
  @Test
  func routerBuildsAndPushesSelectedEpisode() {
    let episode = makeEpisode()
    let destination = UIViewController()
    let episodeBuilder = EpisodeBuilderSpy(destination: destination)
    let dependency = Dependency(episodeBuilder: episodeBuilder)
    let searchViewController = SearchViewControllerStub()
    let navigationController = UINavigationController(rootViewController: searchViewController)
    let router = SearchRouter(dependency: dependency, viewController: searchViewController)

    router.routeToEpisode(episode)

    #expect(episodeBuilder.builtEpisode == episode)
    #expect(navigationController.topViewController === destination)
  }
}

private func makeEpisode() -> Entity.Episode {
  Entity.Episode(
    id: EpisodeID("episode-guid"),
    podcastID: PodcastID(42),
    podcastTitle: "Architecture Talks",
    title: "View-controller-centered RIBs",
    feedURL: URL(string: "https://example.com/feed.xml")!
  )
}

private struct Dependency: SearchDependency {
  let podcastRepository: PodcastRepository = RepositoryStub()
  let episodeRepository: EpisodeRepository = EpisodeRepositoryStub()
  let podcastBuilder: PodcastBuildable
  let episodeBuilder: EpisodeBuildable

  @MainActor
  init(
    podcastBuilder: PodcastBuildable? = nil,
    episodeBuilder: EpisodeBuildable? = nil
  ) {
    self.podcastBuilder = podcastBuilder ?? PodcastBuilderStub()
    self.episodeBuilder = episodeBuilder ?? EpisodeBuilderStub()
  }
}

private struct RepositoryStub: PodcastRepository {
  func fetchTopPodcasts(limit: Int) async throws -> [Podcast] { [] }
  func searchPodcasts(query: String) async throws -> [Podcast] { [] }
  func resolveFeedURL(podcastID: PodcastID) async throws -> URL {
    URL(string: "https://example.com/feed.xml")!
  }
}

private struct EpisodeRepositoryStub: EpisodeRepository {
  func searchEpisodes(query: String) async throws -> [Entity.Episode] { [] }

  func fetchEpisodes(
    podcast: Podcast,
    feedURL: URL,
    limit: Int?
  ) async throws -> [Entity.Episode] {
    []
  }
}

@MainActor
private final class RouterSpy: SearchRouting {
  private(set) var routedPodcast: Podcast?
  private(set) var routedEpisode: Entity.Episode?

  func routeToPodcast(_ podcast: Podcast) {
    routedPodcast = podcast
  }

  func routeToEpisode(_ episode: Entity.Episode) {
    routedEpisode = episode
  }
}

@MainActor
private final class PodcastBuilderSpy: PodcastBuildable {
  private let destination: ViewControllable
  private(set) var builtPodcast: Podcast?

  init(destination: ViewControllable) {
    self.destination = destination
  }

  func build(podcast: Podcast, listener: PodcastListener?) -> ViewControllable {
    builtPodcast = podcast
    return destination
  }
}

@MainActor
private final class PodcastBuilderStub: PodcastBuildable {
  func build(podcast: Podcast, listener: PodcastListener?) -> ViewControllable {
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
private final class EpisodeBuilderStub: EpisodeBuildable {
  func build(episode: Entity.Episode, listener: EpisodeListener?) -> ViewControllable {
    UIViewController()
  }
}

@MainActor
private final class SearchViewControllerStub: UIViewController, SearchControllable {}
