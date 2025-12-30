import UIKit

public protocol _TemplateBuildable {
  @MainActor func build(listener: _TemplateListener?) -> UIViewController
}

@MainActor
public protocol _TemplateListener: AnyObject {
}
