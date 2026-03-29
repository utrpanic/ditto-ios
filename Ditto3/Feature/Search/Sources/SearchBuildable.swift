import RIBsLite

public protocol SearchBuildable {
  @MainActor func build(listener: SearchListener?) -> ViewControllable
}

@MainActor
public protocol SearchListener: AnyObject {}
