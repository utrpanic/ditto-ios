@MainActor
public protocol Routing {}

@MainActor
open class Router<ViewController>: Routing {
  private weak var storedViewController: AnyObject?

  public var viewController: ViewController? {
    storedViewController as? ViewController
  }

  public init(viewController: ViewController) {
    storedViewController = viewController as AnyObject
  }
}
