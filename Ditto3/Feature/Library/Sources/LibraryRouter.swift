import Entity
import Podcast
import RIBsLite

@MainActor
protocol LibraryControllable: ViewControllable {}

@MainActor
protocol LibraryRouting: Routing {
  func routeToPodcast(_ podcast: Podcast)
}

@MainActor
final class LibraryRouter: Router<ViewControllable>, LibraryRouting {
  private let podcastBuilder: PodcastBuildable

  init(dependency: LibraryDependency, viewController: LibraryControllable) {
    self.podcastBuilder = dependency.podcastBuilder
    super.init(viewController: viewController)
  }

  func routeToPodcast(_ podcast: Podcast) {
    let podcastViewController = podcastBuilder.build(podcast: podcast, listener: nil)
    viewController.push(podcastViewController, animated: true)
  }
}
