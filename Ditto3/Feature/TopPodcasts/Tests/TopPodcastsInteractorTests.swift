import Entity
import Foundation
import Podcast
import Repository
import RIBsLite
@testable import TopPodcasts
import Testing
import UIKit

struct TopPodcastsInteractorTests {
  @MainActor
  @Test
  func selectingPodcastRoutesToPodcast() {
    let podcast = makePodcast()
    let interactor = TopPodcastsInteractor(dependency: Dependency())
    let router = RouterSpy()
    interactor.router = router

    interactor.sendAction(.selectPodcast(podcast))

    #expect(router.routedPodcast == podcast)
  }

  @MainActor
  @Test
  func routerBuildsAndPushesSelectedPodcast() {
    let podcast = makePodcast()
    let destination = UIViewController()
    let podcastBuilder = PodcastBuilderSpy(destination: destination)
    let dependency = Dependency(podcastBuilder: podcastBuilder)
    let topPodcastsViewController = TopPodcastsViewControllerStub()
    let navigationController = UINavigationController(rootViewController: topPodcastsViewController)
    let router = TopPodcastsRouter(
      dependency: dependency,
      viewController: topPodcastsViewController
    )

    router.routeToPodcast(podcast)

    #expect(podcastBuilder.builtPodcast == podcast)
    #expect(navigationController.topViewController === destination)
  }
}

private func makePodcast() -> Podcast {
  Podcast(
    id: PodcastID(42),
    title: "Architecture Talks",
    author: "KeepCast"
  )
}

private struct Dependency: TopPodcastsDependency {
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
private final class RouterSpy: TopPodcastsRouting {
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
private final class TopPodcastsViewControllerStub: UIViewController, TopPodcastsControllable {}
