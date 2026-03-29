import RIBsLite

public protocol NewDependency {}

public final class NewBuilder: NewBuildable {
  private let dependency: NewDependency

  public init(dependency: NewDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: NewListener?) -> ViewControllable {
    _ = dependency
    _ = listener
    return NewViewController()
  }
}
