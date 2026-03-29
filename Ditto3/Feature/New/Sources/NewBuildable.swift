import RIBsLite

public protocol NewBuildable {
  @MainActor func build(listener: NewListener?) -> ViewControllable
}

@MainActor
public protocol NewListener: AnyObject {}
