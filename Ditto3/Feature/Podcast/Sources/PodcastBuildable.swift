import Entity
import RIBsLite

public protocol PodcastBuildable: Buildable {
  @MainActor
  func build(podcast: Podcast, listener: PodcastListener?) -> ViewControllable
}

@MainActor
public protocol PodcastListener: AnyObject {}
