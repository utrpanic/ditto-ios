import Entity
import Episode
import Main
import Podcast

enum DeepLink: Equatable, Sendable {
  case main(tab: MainTabDestination)
  case podcast(Podcast)
  case episode(Episode)
}

@MainActor
protocol DeepLinkDependency {
  var podcastBuilder: PodcastBuildable { get }
  var episodeBuilder: EpisodeBuildable { get }
}

@MainActor
final class DeepLinkRouter {
  private let dependency: DeepLinkDependency
  private let mainRouter: MainRouting

  init(
    dependency: DeepLinkDependency,
    mainRouter: MainRouting
  ) {
    self.dependency = dependency
    self.mainRouter = mainRouter
  }

  func route(to deepLink: DeepLink) {
    switch deepLink {
    case let .main(tab):
      mainRouter.routeToMain(tab: tab)
    case let .podcast(podcast):
      let viewController = dependency.podcastBuilder.build(podcast: podcast, listener: nil)
      mainRouter.push(viewController)
    case let .episode(episode):
      let viewController = dependency.episodeBuilder.build(episode: episode, listener: nil)
      mainRouter.push(viewController)
    }
  }
}
