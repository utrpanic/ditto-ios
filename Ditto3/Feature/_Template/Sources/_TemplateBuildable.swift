import RIBsLite

public protocol _TemplateBuildable {
  @MainActor func build(listener: _TemplateListener?) -> ViewControllable
}

@MainActor
public protocol _TemplateListener: AnyObject {}
