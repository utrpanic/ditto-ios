import Discover
import Episode
import Latest
import Library
import Main
import Platform
import Podcast
import Repository
import RepositoryImp
import Search
import UIKit

typealias Dependencies = MainDependency
& DiscoverDependency
& EpisodeDependency
& LatestDependency
& LibraryDependency
& PodcastDependency
& SearchDependency

final class AppComponent: Dependencies {
  let podcastRepository: PodcastRepository
  let episodeRepository: EpisodeRepository

  var mainBuilder: MainBuildable { MainBuilder(dependency: self) }
  var discoverBuilder: DiscoverBuildable { DiscoverBuilder(dependency: self) }
  var latestBuilder: LatestBuildable { LatestBuilder(dependency: self) }
  var libraryBuilder: LibraryBuildable { LibraryBuilder(dependency: self) }
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
