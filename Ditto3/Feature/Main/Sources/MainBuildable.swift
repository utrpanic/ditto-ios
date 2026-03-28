import UIKit

public protocol MainBuildable {
  @MainActor func build(listener: MainListener?) -> UIViewController
}

@MainActor
public protocol MainListener: AnyObject {}
