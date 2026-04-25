import RIBsLite
import UIKit

@MainActor
protocol TopPodcastsControllable: ViewControllable {
  
}

@MainActor
protocol TopPodcastsRouting: Routing {
  
}

@MainActor
final class TopPodcastsRouter: Router<ViewControllable>, TopPodcastsRouting {
  init(dependency: TopPodcastsDependency, viewController: TopPodcastsControllable) {
    super.init(viewController: viewController)
  }
}
