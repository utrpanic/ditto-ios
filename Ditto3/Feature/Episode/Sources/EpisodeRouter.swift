import RIBsLite

@MainActor
protocol EpisodeControllable: ViewControllable {}

@MainActor
protocol EpisodeRouting: Routing {}

@MainActor
final class EpisodeRouter: Router<ViewControllable>, EpisodeRouting {
  init(dependency: EpisodeDependency, viewController: EpisodeControllable) {
    _ = dependency
    super.init(viewController: viewController)
  }
}
