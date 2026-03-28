import Bookmarks
import Main
import New
import Platform
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

  var mainBuildable: MainBuildable { MainBuilder(dependency: self) }
  var topPodcastsBuildable: TopPodcastsBuildable { TopPodcastsBuilder(dependency: self) }
  var newBuildable: NewBuildable { NewBuilder(dependency: self) }
  var bookmarksBuildable: BookmarksBuildable { BookmarksBuilder(dependency: self) }
  var searchBuildable: SearchBuildable { SearchBuilder(dependency: self) }

  init() {
    let session = URLSession.shared
    podcastRepository = PodcastRepositoryImp(session: session)
  }

  @MainActor
  func makeRootViewController() -> UIViewController {
    mainBuildable.build(listener: nil).ui
  }
}
