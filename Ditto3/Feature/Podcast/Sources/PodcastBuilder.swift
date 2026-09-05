import Entity
import RIBsLite

public protocol PodcastDependency: Sendable {}

public final class PodcastBuilder: Builder<PodcastDependency>, PodcastBuildable {
  @MainActor
  public func build(podcast: Podcast, listener: PodcastListener?) -> ViewControllable {
    _ = dependency
    _ = listener
    return PodcastViewController(podcast: podcast)
  }
}
