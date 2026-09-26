import Episode
import Repository
import RIBsLite

public protocol LatestDependency {
  var followingRepository: FollowingRepository { get }
  var podcastRepository: PodcastRepository { get }
  var episodeRepository: EpisodeRepository { get }
  var episodeBuilder: EpisodeBuildable { get }
}

public final class LatestBuilder: Builder<LatestDependency>, LatestBuildable {
  @MainActor
  public func build(listener: LatestListener?) -> ViewControllable {
    let interactor = LatestInteractor(dependency: dependency)
    let viewController = LatestViewController(interactor: interactor)
    let router = LatestRouter(dependency: dependency, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    interactor.activate()
    return viewController
  }
}
