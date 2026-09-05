import Entity
import Podcast
import Repository
import RIBsLite
@testable import Search
import Testing
import UIKit

struct SearchTests {
  @MainActor
  @Test
  func selectingPodcastRoutesToPodcast() {
    let podcast = Podcast(
      id: PodcastID(42),
      title: "Architecture Talks",
      author: "KeepCast"
    )
    let interactor = SearchInteractor(dependency: Dependency())
    let router = RouterSpy()
    interactor.router = router

    interactor.sendAction(.selectPodcast(podcast))

    #expect(router.routedPodcast == podcast)
  }

  @MainActor
  @Test
  func routerBuildsAndPushesSelectedPodcast() {
    let podcast = Podcast(
      id: PodcastID(42),
      title: "Architecture Talks",
      author: "KeepCast"
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
}

private struct Dependency: SearchDependency {
  let podcastRepository: PodcastRepository = RepositoryStub()
  let podcastBuilder: PodcastBuildable

  init(
    podcastBuilder: PodcastBuildable = PodcastBuilder(dependency: PodcastDependencyStub())
  ) {
    self.podcastBuilder = podcastBuilder
  }
}

private struct PodcastDependencyStub: PodcastDependency {}

private struct RepositoryStub: PodcastRepository {
  func fetchTopPodcasts(limit: Int) async throws -> [Podcast] { [] }
  func searchPodcasts(query: String) async throws -> [Podcast] { [] }
}

@MainActor
private final class RouterSpy: SearchRouting {
  private(set) var routedPodcast: Podcast?

  func routeToPodcast(_ podcast: Podcast) {
    routedPodcast = podcast
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
private final class SearchViewControllerStub: UIViewController, SearchControllable {}
