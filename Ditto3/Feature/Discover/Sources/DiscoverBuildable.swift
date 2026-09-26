import RIBsLite

public protocol DiscoverBuildable {
  @MainActor func build(listener: DiscoverListener?) -> ViewControllable
}

@MainActor
public protocol DiscoverListener: AnyObject {}
