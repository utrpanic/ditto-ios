import RIBsLite

public final class TopPodcastsBuilder: TopPodcastsBuildable {
  private let dependency: TopPodcastsDependency

  public init(dependency: TopPodcastsDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: TopPodcastsListener?) -> ViewControllable {
    let interactor = TopPodcastsInteractor(dependency: dependency)
    let viewController = TopPodcastsViewController(interactor: interactor)
    let router = TopPodcastsRouter(dependency: dependency, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    interactor.activate()
    return viewController
  }
}
