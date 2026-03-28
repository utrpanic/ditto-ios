import UIKit

@MainActor
public protocol ViewControllable: AnyObject {
  var ui: UIViewController { get }
}

public extension ViewControllable {
  func present(_ viewControllable: ViewControllable, animated: Bool, completion: (() -> Void)?) {
    self.ui.present(viewControllable.ui, animated: animated, completion: completion)
  }
  
  func dismiss(animated: Bool, completion: (() -> Void)?) {
    self.ui.dismiss(animated: animated)
  }
  
  func push(_ viewControllable: ViewControllable, animated: Bool) {
    self.ui.navigationController?.pushViewController(viewControllable.ui, animated: animated)
  }
  
  func pop(animated: Bool) {
    self.ui.navigationController?.popViewController(animated: animated)
  }
}

public extension ViewControllable where Self: UIViewController {
  var ui: UIViewController { self }
}
