@MainActor
public protocol Interactable: AnyObject {
  func activate()
}

@MainActor
open class Interactor: Interactable {
  public init() {}
  public final func activate() {
    didBecomeActive()
  }

  open func didBecomeActive() {}
}
