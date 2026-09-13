import RIBsLite

public protocol LibraryBuildable {
  @MainActor func build(listener: LibraryListener?) -> ViewControllable
}

@MainActor
public protocol LibraryListener: AnyObject {}
