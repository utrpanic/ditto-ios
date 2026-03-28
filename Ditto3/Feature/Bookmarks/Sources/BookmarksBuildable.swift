import UIKit

public protocol BookmarksBuildable {
  @MainActor func build(listener: BookmarksListener?) -> UIViewController
}

@MainActor
public protocol BookmarksListener: AnyObject {}
