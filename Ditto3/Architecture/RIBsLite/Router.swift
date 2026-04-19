@MainActor
public protocol Routing {}

@MainActor
open class Router<ViewControllable>: Routing {
  public let viewController: ViewControllable

  public init(viewController: ViewControllable) {
    self.viewController = viewController
  }
}
