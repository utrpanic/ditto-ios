@MainActor
public protocol Interactable: AnyObject {
  func activate()
}

@MainActor
open class Interactor<Dependency>: Interactable {
  public let dependency: Dependency
  public init(dependency: Dependency) {
    self.dependency = dependency
  }

  public final func activate() {
    didBecomeActive()
  }

  open func didBecomeActive() {}
}
