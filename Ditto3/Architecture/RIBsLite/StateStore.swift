import Combine

@MainActor
public final class StateStore<State>: ObservableObject {
  @Published public var state: State

  public init(_ initialState: State) {
    self.state = initialState
  }
}
