import Main
import RIBsLite

@MainActor
public final class MainRouterSpy: MainRouting {
  public private(set) var routedTabs: [MainTabDestination] = []
  public private(set) var pushedViewControllers: [ViewControllable] = []

  public init() {}

  public func routeToMain(tab: MainTabDestination) {
    routedTabs.append(tab)
  }

  public func push(_ viewController: ViewControllable) {
    pushedViewControllers.append(viewController)
  }
}
