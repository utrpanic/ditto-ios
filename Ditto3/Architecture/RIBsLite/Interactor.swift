@MainActor
public protocol Interactable: AnyObject {}

@MainActor
open class Interactor: Interactable {
  public init() {}
}
