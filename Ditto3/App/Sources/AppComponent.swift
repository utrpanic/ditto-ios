import Core
import Platform
import TopPodcasts
import UIKit

typealias Dependencies = TopPodcastsDependency

final class AppComponent: Dependencies {
  let podcastRepository: PodcastRepository

  var topPodcastsBuildable: TopPodcastsBuildable { TopPodcastsBuilder(dependency: self) }

  init() {
    let session = URLSession.shared
    podcastRepository = PodcastRepositoryImp(session: session)
  }

  @MainActor
  func makeRootViewController() -> UIViewController {
    UINavigationController(rootViewController: topPodcastsBuildable.build(listener: nil))
  }
}
