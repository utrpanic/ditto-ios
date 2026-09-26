import Episode
import Playback
import Repository
import RIBsLite

@MainActor
public protocol PlayerDependency {
  var episodeBuilder: EpisodeBuildable { get }
  var playbackController: PlaybackControlling { get }
  var playbackQueueRepository: PlaybackQueueRepository { get }
  var playbackSessionRepository: PlaybackSessionRepository { get }
}

public final class PlayerBuilder: Builder<PlayerDependency>, PlayerBuildable {
  @MainActor
  public func build(listener: PlayerListener?) -> PlayerViewControllable {
    let interactor = PlayerInteractor(dependency: dependency)
    let viewController = PlayerViewController(interactor: interactor)
    let router = PlayerRouter(dependency: dependency, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    interactor.activate()
    return viewController
  }
}
