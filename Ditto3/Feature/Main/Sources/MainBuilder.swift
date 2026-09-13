import Discover
import Latest
import Library
import RIBsLite
import Search

public protocol MainDependency {
  var discoverBuilder: DiscoverBuildable { get }
  var latestBuilder: LatestBuildable { get }
  var libraryBuilder: LibraryBuildable { get }
  var searchBuilder: SearchBuildable { get }
}

public final class MainBuilder: Builder<MainDependency>, MainBuildable {
  public func build(listener: MainListener?) -> ViewControllable {
    let interactor = MainInteractor(dependency: dependency)
    let viewController = MainViewController(interactor: interactor)
    let router = MainRouter(dependency: dependency, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    interactor.activate()
    return viewController
  }
}
