import Entity
import RIBsLite

public protocol PlayerBuildable: Buildable {
  @MainActor
  func build(listener: PlayerListener?) -> ViewControllable
}

@MainActor
public protocol PlayerListener: AnyObject {
  func playerDidRequestEpisode(_ episode: Episode)
  func playerVisibilityDidChange(_ isVisible: Bool)
}
