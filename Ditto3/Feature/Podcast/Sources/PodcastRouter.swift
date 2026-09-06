import Entity
import Episode
import RIBsLite

@MainActor
protocol PodcastControllable: ViewControllable {}

@MainActor
protocol PodcastRouting: Routing {
  func routeToEpisode(_ episode: Episode)
}

@MainActor
final class PodcastRouter: Router<ViewControllable>, PodcastRouting {
  private let episodeBuilder: EpisodeBuildable

  init(dependency: PodcastDependency, viewController: PodcastControllable) {
    self.episodeBuilder = dependency.episodeBuilder
    super.init(viewController: viewController)
  }

  func routeToEpisode(_ episode: Episode) {
    let episodeViewController = episodeBuilder.build(episode: episode, listener: nil)
    viewController.push(episodeViewController, animated: true)
  }
}
