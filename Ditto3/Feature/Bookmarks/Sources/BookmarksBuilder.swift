import UIKit

public protocol BookmarksDependency: Sendable {}

public final class BookmarksBuilder: BookmarksBuildable {
  private let dependency: BookmarksDependency

  public init(dependency: BookmarksDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: BookmarksListener?) -> UIViewController {
    _ = dependency
    _ = listener
    return BookmarksViewController()
  }
}
