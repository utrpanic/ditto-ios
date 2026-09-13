import Entity
import Podcast
import RIBsLite

@MainActor
protocol DiscoverControllable: ViewControllable {}

@MainActor
protocol DiscoverRouting: Routing {
  func routeToPodcast(_ podcast: Podcast)
}

@MainActor
final class DiscoverRouter: Router<ViewControllable>, DiscoverRouting {
  private let podcastBuilder: PodcastBuildable

  init(dependency: DiscoverDependency, viewController: DiscoverControllable) {
    self.podcastBuilder = dependency.podcastBuilder
    super.init(viewController: viewController)
  }

  func routeToPodcast(_ podcast: Podcast) {
    let podcastViewController = podcastBuilder.build(podcast: podcast, listener: nil)
    viewController.push(podcastViewController, animated: true)
  }
}
