import Entity
import Episode
import Podcast
import RIBsLite

@MainActor
protocol SearchControllable: ViewControllable {}

@MainActor
protocol SearchRouting: Routing {
  func routeToPodcast(_ podcast: Podcast)
  func routeToEpisode(_ episode: Entity.Episode)
}

@MainActor
final class SearchRouter: Router<ViewControllable>, SearchRouting {
  private let podcastBuilder: PodcastBuildable
  private let episodeBuilder: EpisodeBuildable

  init(dependency: SearchDependency, viewController: SearchControllable) {
    self.podcastBuilder = dependency.podcastBuilder
    self.episodeBuilder = dependency.episodeBuilder
    super.init(viewController: viewController)
  }

  func routeToPodcast(_ podcast: Podcast) {
    let podcastViewController = podcastBuilder.build(podcast: podcast, listener: nil)
    viewController.push(podcastViewController, animated: true)
  }

  func routeToEpisode(_ episode: Entity.Episode) {
    let episodeViewController = episodeBuilder.build(episode: episode, listener: nil)
    viewController.push(episodeViewController, animated: true)
  }
}
