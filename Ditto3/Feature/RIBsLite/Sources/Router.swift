@MainActor
public protocol Routing: AnyObject {
  associatedtype Dependency
  associatedtype ViewControllable
  var dependency: Dependency { get }
  var viewController: ViewControllable { get }
}

@MainActor
open class Router<Dependency, ViewControllable>: Routing {
  public let dependency: Dependency
  public let viewController: ViewControllable

  public init(dependency: Dependency, viewController: ViewControllable) {
    self.dependency = dependency
    self.viewController = viewController
  }
}
