import Combine
import Observation

@MainActor
@Observable
public final class StateStore<State> {
  public var state: State {
    didSet {
      stateDidChangeSubject.send(state)
    }
  }

  private let stateDidChangeSubject: PassthroughSubject<State, Never>

  /// Emits synchronously on the main actor after each state mutation.
  /// Does not replay the current state; read `state` for the initial value.
  public let stateDidChange: AnyPublisher<State, Never>

  public init(_ initialState: State) {
    let subject = PassthroughSubject<State, Never>()
    self.stateDidChangeSubject = subject
    self.stateDidChange = subject.eraseToAnyPublisher()
    self.state = initialState
  }
}
