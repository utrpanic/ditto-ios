import Entity
import RIBsLite

public protocol EpisodeBuildable: Buildable {
  @MainActor
  func build(episode: Episode, listener: EpisodeListener?) -> ViewControllable
}

@MainActor
public protocol EpisodeListener: AnyObject {}
