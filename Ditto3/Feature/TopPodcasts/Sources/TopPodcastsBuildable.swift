import UIKit

public protocol TopPodcastsBuildable {
  @MainActor func build(listener: TopPodcastsListener?) -> UIViewController
}

@MainActor
public protocol TopPodcastsListener: AnyObject {}
