import RIBsLite

public protocol MainBuildable: Buildable {
  @MainActor func build(listener: MainListener?) -> ViewControllable
}

public protocol MainListener: AnyObject {}
