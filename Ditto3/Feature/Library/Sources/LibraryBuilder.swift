import RIBsLite

public protocol LibraryDependency {}

public final class LibraryBuilder: LibraryBuildable {
  private let dependency: LibraryDependency

  public init(dependency: LibraryDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: LibraryListener?) -> ViewControllable {
    _ = dependency
    _ = listener
    return LibraryViewController()
  }
}
