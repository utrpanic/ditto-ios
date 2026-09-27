import Entity
import Episode
import FeatureTestSupport
import Foundation
import Main
import Podcast
import RIBsLite
import Testing
@testable import App

@MainActor
struct DeepLinkRouterTests {
  private let sut: DeepLinkRouter
  private let mainRouter: MainRouterSpy
  private let podcastBuilder: PodcastBuilderSpy
  private let episodeBuilder: EpisodeBuilderSpy

  init() {
    let mainRouter = MainRouterSpy()
    let podcastBuilder = PodcastBuilderSpy()
    let episodeBuilder = EpisodeBuilderSpy()
    self.sut = DeepLinkRouter(
      dependency: DeepLinkDependencyStub(
        podcastBuilder: podcastBuilder,
        episodeBuilder: episodeBuilder
      ),
      mainNavigation: mainRouter
    )
    self.mainRouter = mainRouter
    self.podcastBuilder = podcastBuilder
    self.episodeBuilder = episodeBuilder
  }

  @Test
  func routesMainToRequestedTab() {
    sut.route(to: .main(tab: .latest))

    #expect(mainRouter.routedTabs == [.latest])
    #expect(mainRouter.pushedViewControllers.isEmpty)
    #expect(podcastBuilder.buildCallCount == 0)
    #expect(episodeBuilder.buildCallCount == 0)
  }

  @Test
  func buildsAndPushesPodcast() {
    let podcast = Podcast(id: PodcastID(42), title: "Architecture Talks", author: "Ditto")

    sut.route(to: .podcast(podcast))

    #expect(podcastBuilder.buildCallCount == 1)
    #expect(podcastBuilder.builtPodcast == podcast)
    #expect(mainRouter.pushedViewControllers.count == 1)
    #expect(mainRouter.pushedViewControllers.first?.ui === podcastBuilder.viewController.ui)
    #expect(mainRouter.routedTabs.isEmpty)
    #expect(episodeBuilder.buildCallCount == 0)
  }

  @Test
  func buildsAndPushesEpisode() throws {
    let episode = Episode(
      id: EpisodeID("episode-guid"),
      podcastTitle: "Architecture Talks",
      title: "View-controller-centered RIBs",
      feedURL: try #require(URL(string: "https://example.com/feed.xml"))
    )

    sut.route(to: .episode(episode))

    #expect(episodeBuilder.buildCallCount == 1)
    #expect(episodeBuilder.builtEpisode == episode)
    #expect(mainRouter.pushedViewControllers.count == 1)
    #expect(mainRouter.pushedViewControllers.first?.ui === episodeBuilder.viewController.ui)
    #expect(mainRouter.routedTabs.isEmpty)
    #expect(podcastBuilder.buildCallCount == 0)
  }
}

@MainActor
private struct DeepLinkDependencyStub: DeepLinkDependency {
  let podcastBuilder: PodcastBuildable
  let episodeBuilder: EpisodeBuildable
}
