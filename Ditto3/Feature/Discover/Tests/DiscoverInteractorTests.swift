import Entity
import Foundation
import Podcast
import Repository
import RIBsLite
@testable import Discover
import Testing
import UIKit

struct DiscoverInteractorTests {
  @MainActor
  @Test
  func selectingPodcastRoutesToPodcast() {
    let podcast = makePodcast()
    let interactor = DiscoverInteractor(dependency: Dependency())
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
    let discoverViewController = DiscoverViewControllerStub()
    let navigationController = UINavigationController(rootViewController: discoverViewController)
    let router = DiscoverRouter(
      dependency: dependency,
      viewController: discoverViewController
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
    author: "Ditto"
  )
}

private struct Dependency: DiscoverDependency {
  let podcastRepository: PodcastRepository = RepositoryStub()
  let podcastBuilder: PodcastBuildable

  @MainActor
  init(
    podcastBuilder: PodcastBuildable? = nil
  ) {
    self.podcastBuilder = podcastBuilder ?? PodcastBuilderStub()
  }
}

private struct RepositoryStub: PodcastRepository {
  func fetchTopPodcasts(limit: Int) async throws -> [Podcast] { [] }
  func searchPodcasts(query: String) async throws -> [Podcast] { [] }
  func resolveFeedURL(podcastID: PodcastID) async throws -> URL {
    URL(string: "https://example.com/feed.xml")!
  }
}

@MainActor
private final class RouterSpy: DiscoverRouting {
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
private final class PodcastBuilderStub: PodcastBuildable {
  func build(podcast: Podcast, listener: PodcastListener?) -> ViewControllable {
    UIViewController()
  }
}

@MainActor
private final class DiscoverViewControllerStub: UIViewController, DiscoverControllable {}
