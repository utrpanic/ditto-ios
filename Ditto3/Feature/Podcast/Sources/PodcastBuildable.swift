import UIKit

public protocol PodcastBuildable {
  @MainActor func build(listener: PodcastListener?) -> UIViewController
}

@MainActor
public protocol PodcastListener: AnyObject {}
