import RIBsLite

public final class DiscoverBuilder: DiscoverBuildable {
  private let dependency: DiscoverDependency

  public init(dependency: DiscoverDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: DiscoverListener?) -> ViewControllable {
    let interactor = DiscoverInteractor(dependency: dependency)
    let viewController = DiscoverViewController(interactor: interactor)
    let router = DiscoverRouter(dependency: dependency, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    interactor.activate()
    return viewController
  }
}
