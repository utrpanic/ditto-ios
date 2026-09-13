import Entity
import Foundation
import Podcast
import Repository
import RIBsLite
@testable import Library
import Testing
import UIKit

struct LibraryTests {
  @MainActor
  @Test
  func builderConnectsLibraryRIB() throws {
    let listener = Listener()
    let builder = LibraryBuilder(dependency: Dependency())

    let result = builder.build(listener: listener)

    let viewController = try #require(result as? LibraryViewController)
    let interactor = try #require(viewController.interactor as? LibraryInteractor)
    #expect(interactor.listener === listener)
    #expect(interactor.router != nil)
  }

  @MainActor
  @Test
  func activationLoadsFollowedPodcasts() async {
    let followedPodcast = makeFollowedPodcast()
    let repository = FollowingRepositorySpy(followedPodcasts: [followedPodcast])
    let interactor = LibraryInteractor(dependency: Dependency(followingRepository: repository))

    interactor.activate()
    await waitUntil {
      interactor.store.state == .loaded([followedPodcast])
    }

    #expect(interactor.store.state == .loaded([followedPodcast]))
  }

  @MainActor
  @Test
  func followingChangesRefreshLibrary() async {
    let repository = FollowingRepositorySpy()
    let interactor = LibraryInteractor(dependency: Dependency(followingRepository: repository))
    let podcast = makePodcast()
    interactor.activate()
    await waitUntil { interactor.store.state == .loaded([]) }

    await repository.follow(podcast)
    await waitUntil {
      guard case .loaded(let followedPodcasts) = interactor.store.state else { return false }
      return followedPodcasts.map(\.podcast) == [podcast]
    }

    guard case .loaded(let followedPodcasts) = interactor.store.state else {
      Issue.record("Expected a loaded library state.")
      return
    }
    #expect(followedPodcasts.map(\.podcast) == [podcast])
  }

  @MainActor
  @Test
  func selectingPodcastRoutesToPodcast() {
    let podcast = makePodcast()
    let interactor = LibraryInteractor(dependency: Dependency())
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
    let libraryViewController = LibraryViewControllerStub()
    let navigationController = UINavigationController(rootViewController: libraryViewController)
    let router = LibraryRouter(dependency: dependency, viewController: libraryViewController)

    router.routeToPodcast(podcast)

    #expect(podcastBuilder.builtPodcast == podcast)
    #expect(navigationController.topViewController === destination)
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
    author: "Ditto"
  )
}

private func makeFollowedPodcast() -> FollowedPodcast {
  FollowedPodcast(
    podcast: makePodcast(),
    followedAt: Date(timeIntervalSince1970: 1_000)
  )
}

private struct Dependency: LibraryDependency {
  let followingRepository: FollowingRepository
  let podcastBuilder: PodcastBuildable

  @MainActor
  init(
    followingRepository: FollowingRepository = FollowingRepositorySpy(),
    podcastBuilder: PodcastBuildable? = nil
  ) {
    self.followingRepository = followingRepository
    self.podcastBuilder = podcastBuilder ?? PodcastBuilderStub()
  }
}

private actor FollowingRepositorySpy: FollowingRepository {
  private var followedPodcasts: [FollowedPodcast]
  private var changeContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]

  init(followedPodcasts: [FollowedPodcast] = []) {
    self.followedPodcasts = followedPodcasts
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

@MainActor
private final class Listener: LibraryListener {}

@MainActor
private final class RouterSpy: LibraryRouting {
  private(set) var routedPodcast: Podcast?

  func routeToPodcast(_ podcast: Podcast) {
    routedPodcast = podcast
  }
}

@MainActor
private final class PodcastBuilderStub: PodcastBuildable {
  func build(podcast: Podcast, listener: PodcastListener?) -> ViewControllable {
    UIViewController()
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
private final class LibraryViewControllerStub: UIViewController, LibraryControllable {}
