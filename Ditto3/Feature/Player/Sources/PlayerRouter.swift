import RIBsLite

@MainActor
protocol PlayerViewControllable: ViewControllable {}

@MainActor
protocol PlayerRouting: Routing {}

@MainActor
final class PlayerRouter: Router<PlayerViewControllable>, PlayerRouting {
  init(dependency: PlayerDependency, viewController: PlayerViewControllable) {
    _ = dependency
    super.init(viewController: viewController)
  }
}
