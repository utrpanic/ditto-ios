import AVFoundation
import Discover
import Episode
import Latest
import Library
import Main
import MediaPlayer
import Platform
import Playback
import PlaybackImp
import Player
import Podcast
import Repository
import RepositoryImp
import RIBsLite
import Search
import UIKit

typealias Dependencies = MainDependency
& DeepLinkDependency
& DiscoverDependency
& EpisodeDependency
& LatestDependency
& LibraryDependency
& PodcastDependency
& PlayerDependency
& SearchDependency

@MainActor
final class AppComponent: @MainActor Dependencies {
  let podcastRepository: PodcastRepository
  let episodeRepository: EpisodeRepository
  let followingRepository: FollowingRepository
  let playbackQueueRepository: PlaybackQueueRepository
  let playbackSessionRepository: PlaybackSessionRepository
  let playbackController: PlaybackControlling

  var mainBuilder: MainBuildable { MainBuilder(dependency: self) }
  var discoverBuilder: DiscoverBuildable { DiscoverBuilder(dependency: self) }
  var latestBuilder: LatestBuildable { LatestBuilder(dependency: self) }
  var libraryBuilder: LibraryBuildable { LibraryBuilder(dependency: self) }
  var searchBuilder: SearchBuildable { SearchBuilder(dependency: self) }
  var podcastBuilder: PodcastBuildable { PodcastBuilder(dependency: self) }
  var episodeBuilder: EpisodeBuildable { EpisodeBuilder(dependency: self) }
  var playerBuilder: PlayerBuildable { PlayerBuilder(dependency: self) }

  init() {
    let session = URLSession.shared
    podcastRepository = PodcastRepositoryImp(session: session)
    episodeRepository = EpisodeRepositoryImp(session: session)
    followingRepository = FollowingRepositoryImp(userDefaults: UserDefaults.standard)
    playbackQueueRepository = PlaybackQueueRepositoryImp(userDefaults: UserDefaults.standard)
    playbackSessionRepository = PlaybackSessionRepositoryImp(userDefaults: UserDefaults.standard)
    playbackController = PlaybackControllerImp(
      player: AVPlayer(),
      audioSession: AVAudioSession.sharedInstance(),
      remoteCommandCenter: MPRemoteCommandCenter.shared(),
      nowPlayingInfoCenter: MPNowPlayingInfoCenter.default()
    )
  }

  @MainActor
  func makeRoot() -> (ViewControllable, MainRouting) {
    mainBuilder.build(listener: nil)
  }
}
