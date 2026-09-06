import Entity
import Episode
import Repository
import RIBsLite

public protocol PodcastDependency {
  var podcastRepository: PodcastRepository { get }
  var episodeRepository: EpisodeRepository { get }
  var episodeBuilder: EpisodeBuildable { get }
}

public final class PodcastBuilder: Builder<PodcastDependency>, PodcastBuildable {
  @MainActor
  public func build(podcast: Podcast, listener: PodcastListener?) -> ViewControllable {
    let interactor = PodcastInteractor(podcast: podcast, dependency: dependency)
    let viewController = PodcastViewController(interactor: interactor)
    let router = PodcastRouter(dependency: dependency, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    interactor.activate()
    return viewController
  }
}
