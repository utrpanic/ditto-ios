import Playback
import RIBsLite

@MainActor
public protocol PlayerDependency {
  var playbackController: PlaybackControlling { get }
}

public final class PlayerBuilder: Builder<PlayerDependency>, PlayerBuildable {
  @MainActor
  public func build(listener: PlayerListener?) -> ViewControllable {
    let interactor = PlayerInteractor(dependency: dependency)
    let viewController = PlayerViewController(interactor: interactor)
    let router = PlayerRouter(viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    interactor.activate()
    return viewController
  }
}
