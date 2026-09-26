@MainActor
public protocol Routing {}

@MainActor
open class Router<ViewController>: Routing {
  private weak var storedViewController: AnyObject?

  public var viewController: ViewController {
    guard let viewController = storedViewController as? ViewController else {
      preconditionFailure("The routed view controller has been released.")
    }

    return viewController
  }

  public init(viewController: ViewController) {
    storedViewController = viewController as AnyObject
  }
}
