import Entity
import Podcast
import RIBsLite
import UIKit

@MainActor
public final class PodcastBuilderSpy: PodcastBuildable {
  public let viewController: ViewControllable
  public private(set) var buildCallCount = 0
  public private(set) var builtPodcast: Podcast?

  public init(viewController: ViewControllable = UIViewController()) {
    self.viewController = viewController
  }

  public func build(podcast: Podcast, listener: PodcastListener?) -> ViewControllable {
    buildCallCount += 1
    builtPodcast = podcast
    return viewController
  }
}
