import Podcast
import Repository
import RIBsLite

public protocol LibraryDependency {
  var followingRepository: FollowingRepository { get }
  var podcastBuilder: PodcastBuildable { get }
}

public final class LibraryBuilder: Builder<LibraryDependency>, LibraryBuildable {
  @MainActor
  public func build(listener: LibraryListener?) -> ViewControllable {
    let interactor = LibraryInteractor(dependency: dependency)
    let viewController = LibraryViewController(interactor: interactor)
    let router = LibraryRouter(dependency: dependency, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    interactor.activate()
    return viewController
  }
}
