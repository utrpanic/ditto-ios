import Bookmarks
import New
import RIBsLite
import Search
import TopPodcasts

public protocol MainDependency {
  var topPodcastsBuildable: TopPodcastsBuildable { get }
  var newBuildable: NewBuildable { get }
  var bookmarksBuildable: BookmarksBuildable { get }
  var searchBuildable: SearchBuildable { get }
}

public final class MainBuilder: Builder<MainDependency>, MainBuildable {
  @MainActor
  public func build(listener: MainListener?) -> ViewControllable {
    let interactor = MainInteractor(dependency: dependency)
    let viewController = MainViewController(interactor: interactor, listener: interactor)
    let router = MainRouter(dependency: dependency, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    interactor.activate()
    return viewController
  }
}
