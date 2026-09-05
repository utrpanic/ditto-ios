import Entity
import Podcast
import RIBsLite

@MainActor
protocol TopPodcastsControllable: ViewControllable {}

@MainActor
protocol TopPodcastsRouting: Routing {
  func routeToPodcast(_ podcast: Podcast)
}

@MainActor
final class TopPodcastsRouter: Router<ViewControllable>, TopPodcastsRouting {
  private let podcastBuilder: PodcastBuildable

  init(dependency: TopPodcastsDependency, viewController: TopPodcastsControllable) {
    self.podcastBuilder = dependency.podcastBuilder
    super.init(viewController: viewController)
  }

  func routeToPodcast(_ podcast: Podcast) {
    let podcastViewController = podcastBuilder.build(podcast: podcast, listener: nil)
    viewController.push(podcastViewController, animated: true)
  }
}
