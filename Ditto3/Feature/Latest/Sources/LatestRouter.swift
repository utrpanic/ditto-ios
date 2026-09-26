import Entity
import Episode
import RIBsLite

@MainActor
protocol LatestControllable: ViewControllable {}

@MainActor
protocol LatestRouting: Routing {
  func routeToEpisode(_ episode: Entity.Episode)
}

@MainActor
final class LatestRouter: Router<ViewControllable>, LatestRouting {
  private let episodeBuilder: EpisodeBuildable

  init(dependency: LatestDependency, viewController: LatestControllable) {
    self.episodeBuilder = dependency.episodeBuilder
    super.init(viewController: viewController)
  }

  func routeToEpisode(_ episode: Entity.Episode) {
    let episodeViewController = episodeBuilder.build(episode: episode, listener: nil)
    viewController.push(episodeViewController, animated: true)
  }
}
