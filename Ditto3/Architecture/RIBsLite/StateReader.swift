import SwiftUI

@MainActor
public struct StateReader<State, Content: View>: View {
  @ObservedObject private var store: StateStore<State>
  private let content: (State) -> Content

  public init(store: StateStore<State>, @ViewBuilder content: @escaping (State) -> Content) {
    self.store = store
    self.content = content
  }

  public var body: some View {
    content(store.state)
  }
}
