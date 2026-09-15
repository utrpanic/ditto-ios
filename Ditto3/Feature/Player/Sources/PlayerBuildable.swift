import RIBsLite

public protocol PlayerBuildable: Buildable {
  @MainActor
  func build(listener: PlayerListener?) -> PlayerViewControllable
}

@MainActor
public protocol PlayerListener: AnyObject {}

@MainActor
public protocol PlayerViewControllable: ViewControllable {
  func observeVisibility(_ observer: @escaping (Bool) -> Void)
}
