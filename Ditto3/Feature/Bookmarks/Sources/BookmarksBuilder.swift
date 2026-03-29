import RIBsLite

public protocol BookmarksDependency {}

public final class BookmarksBuilder: BookmarksBuildable {
  private let dependency: BookmarksDependency

  public init(dependency: BookmarksDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: BookmarksListener?) -> ViewControllable {
    _ = dependency
    _ = listener
    return BookmarksViewController()
  }
}
