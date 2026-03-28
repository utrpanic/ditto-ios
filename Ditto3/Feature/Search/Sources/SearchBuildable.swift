import UIKit

public protocol SearchBuildable {
  @MainActor func build(listener: SearchListener?) -> UIViewController
}

@MainActor
public protocol SearchListener: AnyObject {}
