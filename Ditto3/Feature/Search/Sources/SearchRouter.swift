import Entity
import Podcast
import RIBsLite

@MainActor
protocol SearchControllable: ViewControllable {}

@MainActor
protocol SearchRouting: Routing {
  func routeToPodcast(_ podcast: Podcast)
}

@MainActor
final class SearchRouter: Router<ViewControllable>, SearchRouting {
  private let podcastBuilder: PodcastBuildable

  init(dependency: SearchDependency, viewController: SearchControllable) {
    self.podcastBuilder = dependency.podcastBuilder
    super.init(viewController: viewController)
  }

  func routeToPodcast(_ podcast: Podcast) {
    let podcastViewController = podcastBuilder.build(podcast: podcast, listener: nil)
    viewController.push(podcastViewController, animated: true)
  }
}
