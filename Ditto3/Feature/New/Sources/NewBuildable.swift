import UIKit

public protocol NewBuildable {
  @MainActor func build(listener: NewListener?) -> UIViewController
}

@MainActor
public protocol NewListener: AnyObject {}
