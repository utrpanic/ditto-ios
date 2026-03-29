import RIBsLite

public protocol TopPodcastsBuildable {
  @MainActor func build(listener: TopPodcastsListener?) -> ViewControllable
}

@MainActor
public protocol TopPodcastsListener: AnyObject {}
