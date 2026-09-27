import Entity
import Episode
import RIBsLite
import UIKit

@MainActor
protocol PlayerViewControllable: ViewControllable {}

@MainActor
protocol PlayerRouting: Routing {
  func routeToEpisode(_ episode: Entity.Episode)
}

@MainActor
final class PlayerRouter: Router<PlayerViewControllable>, PlayerRouting {
  private let episodeBuilder: EpisodeBuildable

  init(dependency: PlayerDependency, viewController: PlayerViewControllable) {
    self.episodeBuilder = dependency.episodeBuilder
    super.init(viewController: viewController)
  }

  func routeToEpisode(_ episode: Entity.Episode) {
    let episodeViewController = episodeBuilder.build(episode: episode, listener: nil)
    let tabBarController = viewController.ui.parent as? UITabBarController
    let navigationController = tabBarController?.selectedViewController as? UINavigationController
    navigationController?.pushViewController(episodeViewController.ui, animated: true)
  }
}
