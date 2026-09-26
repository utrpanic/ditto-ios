import Discover
import Latest
import Library
import Player
import RIBsLite
import Search

public protocol MainDependency {
  var discoverBuilder: DiscoverBuildable { get }
  var latestBuilder: LatestBuildable { get }
  var libraryBuilder: LibraryBuildable { get }
  var playerBuilder: PlayerBuildable { get }
  var searchBuilder: SearchBuildable { get }
}

public final class MainBuilder: Builder<MainDependency>, MainBuildable {
  public func build(listener: MainListener?) -> (ViewControllable, MainRouting) {
    let interactor = MainInteractor()
    let viewController = MainViewController(interactor: interactor)
    let router = MainRouter(
      dependency: dependency,
      interactor: interactor,
      viewController: viewController
    )
    interactor.router = router
    interactor.listener = listener
    interactor.activate()
    return (viewController, router)
  }
}
