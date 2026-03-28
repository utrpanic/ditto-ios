import UIKit

public protocol PodcastDependency: Sendable {}

public final class PodcastBuilder: PodcastBuildable {
  private let dependency: PodcastDependency

  public init(dependency: PodcastDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: PodcastListener?) -> UIViewController {
    _ = dependency
    _ = listener
    return PodcastViewController()
  }
}
