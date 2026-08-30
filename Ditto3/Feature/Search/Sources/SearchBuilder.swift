import Repository
import RIBsLite

public protocol SearchDependency {
  var podcastRepository: PodcastRepository { get }
}

public final class SearchBuilder: SearchBuildable {
  private let dependency: SearchDependency

  public init(dependency: SearchDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: SearchListener?) -> ViewControllable {
    let interactor = SearchInteractor(dependency: dependency)
    let viewController = SearchViewController(interactor: interactor)
    let router = SearchRouter(dependency: dependency, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    interactor.activate()
    return viewController
  }
}
