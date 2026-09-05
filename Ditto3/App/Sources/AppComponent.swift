import Bookmarks
import Main
import New
import Platform
import Podcast
import Repository
import RepositoryImp
import Search
import TopPodcasts
import UIKit

typealias Dependencies = MainDependency
& BookmarksDependency
& NewDependency
& SearchDependency
& TopPodcastsDependency

final class AppComponent: Dependencies {
  let podcastRepository: PodcastRepository

  var mainBuilder: MainBuildable { MainBuilder(dependency: self) }
  var topPodcastsBuilder: TopPodcastsBuildable { TopPodcastsBuilder(dependency: self) }
  var newBuilder: NewBuildable { NewBuilder(dependency: self) }
  var bookmarksBuilder: BookmarksBuildable { BookmarksBuilder(dependency: self) }
  var searchBuilder: SearchBuildable { SearchBuilder(dependency: self) }
  var podcastBuilder: PodcastBuildable { PodcastBuilder(dependency: PodcastComponent()) }

  init() {
    let session = URLSession.shared
    podcastRepository = PodcastRepositoryImp(session: session)
  }

  @MainActor
  func makeRootViewController() -> UIViewController {
    mainBuilder.build(listener: nil).ui
  }
}

private struct PodcastComponent: PodcastDependency {}
