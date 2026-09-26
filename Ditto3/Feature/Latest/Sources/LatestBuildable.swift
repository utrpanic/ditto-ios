import RIBsLite

public protocol LatestBuildable {
  @MainActor func build(listener: LatestListener?) -> ViewControllable
}

@MainActor
public protocol LatestListener: AnyObject {}
