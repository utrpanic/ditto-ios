import Bookmarks
import New
import RIBsLite
import Search
import TopPodcasts

public protocol MainDependency {
  var topPodcastsBuilder: TopPodcastsBuildable { get }
  var newBuilder: NewBuildable { get }
  var bookmarksBuilder: BookmarksBuildable { get }
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
