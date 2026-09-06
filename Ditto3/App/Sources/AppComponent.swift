import Bookmarks
import Episode
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
& EpisodeDependency
& NewDependency
& PodcastDependency
& SearchDependency
& TopPodcastsDependency

final class AppComponent: Dependencies {
  let podcastRepository: PodcastRepository
  let episodeRepository: EpisodeRepository

  var mainBuilder: MainBuildable { MainBuilder(dependency: self) }
  var topPodcastsBuilder: TopPodcastsBuildable { TopPodcastsBuilder(dependency: self) }
  var newBuilder: NewBuildable { NewBuilder(dependency: self) }
  var bookmarksBuilder: BookmarksBuildable { BookmarksBuilder(dependency: self) }
  var searchBuilder: SearchBuildable { SearchBuilder(dependency: self) }
  var podcastBuilder: PodcastBuildable { PodcastBuilder(dependency: self) }
  var episodeBuilder: EpisodeBuildable { EpisodeBuilder(dependency: self) }

  init() {
    let session = URLSession.shared
    podcastRepository = PodcastRepositoryImp(session: session)
    episodeRepository = EpisodeRepositoryImp(session: session)
  }

  @MainActor
  func makeRootViewController() -> UIViewController {
    mainBuilder.build(listener: nil).ui
  }
}
