import Combine
import Feature
import UIKit

public final class _TemplateBuildableMock: _TemplateBuildable, @unchecked Sendable {
  public init() {}
  
  public var buildCallCount = 0
  public func build(listener: _TemplateListener?) -> UIViewController {
    buildCallCount += 1
    return UIViewController()
  }
}
