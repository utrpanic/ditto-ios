import RIBsLite

public protocol BookmarksBuildable {
  @MainActor func build(listener: BookmarksListener?) -> ViewControllable
}

@MainActor
public protocol BookmarksListener: AnyObject {}
