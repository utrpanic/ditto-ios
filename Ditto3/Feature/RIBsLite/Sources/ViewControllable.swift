import UIKit

@MainActor
public protocol ViewControllable: AnyObject {
  var ui: UIViewController { get }
}

public extension ViewControllable {
  func present(_ viewController: ViewControllable, animated: Bool, completion: (() -> Void)?) {
    self.ui.present(viewController.ui, animated: animated, completion: completion)
  }
  
  func dismiss(animated: Bool, completion: (() -> Void)?) {
    self.ui.dismiss(animated: animated, completion: completion)
  }
  
  func push(_ viewController: ViewControllable, animated: Bool) {
    self.ui.navigationController?.pushViewController(viewController.ui, animated: animated)
  }
  
  func pop(animated: Bool) {
    self.ui.navigationController?.popViewController(animated: animated)
  }
}

extension UIViewController: ViewControllable {
  public var ui: UIViewController { self }
}
