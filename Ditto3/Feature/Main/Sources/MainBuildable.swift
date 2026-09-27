import Entity
import RIBsLite

public enum MainTabDestination: Equatable, Sendable {
  case discover
  case latest
  case library
  case search
}

@MainActor
public protocol MainRouting: Routing {
  func routeToEpisode(_ episode: Episode)
  func routeToMain(tab: MainTabDestination)
  func push(_ viewController: ViewControllable)
}

public protocol MainBuildable: Buildable {
  @MainActor func build(listener: MainListener?) -> (ViewControllable, MainRouting)
}

public protocol MainListener: AnyObject {}
