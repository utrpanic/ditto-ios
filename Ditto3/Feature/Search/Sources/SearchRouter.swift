import RIBsLite

@MainActor
protocol SearchControllable: ViewControllable {}

@MainActor
protocol SearchRouting: Routing {}

@MainActor
final class SearchRouter: Router<ViewControllable>, SearchRouting {
  init(dependency: SearchDependency, viewController: SearchControllable) {
    _ = dependency
    super.init(viewController: viewController)
  }
}
