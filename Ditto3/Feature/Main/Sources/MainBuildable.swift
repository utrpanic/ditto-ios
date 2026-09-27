import RIBsLite

public enum MainTabDestination: Equatable, Sendable {
  case discover
  case latest
  case library
  case search
}

@MainActor
public protocol MainNavigation: Routing {
  func selectTab(_ tab: MainTabDestination)
  func push(_ viewController: ViewControllable)
}

public protocol MainBuildable: Buildable {
  @MainActor func build(listener: MainListener?) -> (ViewControllable, MainNavigation)
}

public protocol MainListener: AnyObject {}
