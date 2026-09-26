import Entity
import Episode
import RIBsLite
import UIKit

@MainActor
public final class EpisodeBuilderSpy: EpisodeBuildable {
  public let viewController: ViewControllable
  public private(set) var buildCallCount = 0
  public private(set) var builtEpisode: Entity.Episode?

  public init(viewController: ViewControllable = UIViewController()) {
    self.viewController = viewController
  }

  public func build(episode: Entity.Episode, listener: EpisodeListener?) -> ViewControllable {
    buildCallCount += 1
    builtEpisode = episode
    return viewController
  }
}
