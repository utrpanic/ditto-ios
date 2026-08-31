import Entity
import RIBsLite

public protocol EpisodeDependency {}

public final class EpisodeBuilder: Builder<EpisodeDependency>, EpisodeBuildable {
  @MainActor
  public func build(episode: Episode, listener: EpisodeListener?) -> ViewControllable {
    let interactor = EpisodeInteractor(episode: episode)
    let viewController = EpisodeViewController(interactor: interactor)
    let router = EpisodeRouter(dependency: dependency, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    interactor.activate()
    return viewController
  }
}
