import Entity
import Repository
import RIBsLite

public protocol EpisodeDependency {
  var keepRepository: KeepRepository { get }
}

public final class EpisodeBuilder: Builder<EpisodeDependency>, EpisodeBuildable {
  @MainActor
  public func build(episode: Episode, listener: EpisodeListener?) -> ViewControllable {
    let interactor = EpisodeInteractor(episode: episode, dependency: dependency)
    let viewController = EpisodeViewController(interactor: interactor)
    let router = EpisodeRouter(dependency: dependency, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    interactor.activate()
    return viewController
  }
}
