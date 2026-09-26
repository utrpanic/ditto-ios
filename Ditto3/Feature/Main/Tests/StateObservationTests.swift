import Combine
import Observation
import RIBsLite
import SwiftUI
import Synchronization
import Testing
import UIKit

struct StateObservationTests {
  @MainActor
  @Test
  func publisherEmitsCommittedStateSynchronouslyAndStopsAfterCancellation() {
    struct State: Equatable {
      var count = 0
    }
    let store = StateStore(State())
    var receivedCounts: [Int] = []
    let cancellable = store.stateDidChange.sink { state in
      #expect(store.state == state)
      receivedCounts.append(state.count)
    }
    #expect(receivedCounts.isEmpty)

    store.state = State(count: 1)
    #expect(receivedCounts == [1])

    store.state.count += 1
    #expect(receivedCounts == [1, 2])

    store.state = State(count: 2)
    #expect(receivedCounts == [1, 2, 2])

    cancellable.cancel()
    store.state.count = 3
    #expect(receivedCounts == [1, 2, 2])
  }

  @MainActor
  @Test
  func storeTracksReplacementAndNestedMutation() {
    struct State {
      var count = 0
    }
    let store = StateStore(State())
    let changes = Mutex(0)

    func track() {
      withObservationTracking {
        _ = store.state.count
      } onChange: {
        changes.withLock { $0 += 1 }
      }
    }

    track()
    store.state = State(count: 1)
    #expect(changes.withLock { $0 } == 1)
    #expect(store.state.count == 1)

    track()
    store.state.count += 1
    #expect(changes.withLock { $0 } == 2)
    #expect(store.state.count == 2)
  }

  @MainActor
  @Test
  func stateReaderUpdatesHostedContentAfterRepeatedChanges() async {
    let store = StateStore(0)
    var renderedValue: Int?
    let viewController = UIHostingController(rootView: StateReader(store: store) { value in
      renderedValue = value
      return Text("\(value)")
    })
    // These hostless unit tests have no UIWindowScene; use a standalone test window.
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
    window.rootViewController = viewController
    window.isHidden = false
    defer { window.isHidden = true }

    for value in 0...2 {
      store.state = value
      for _ in 0..<100 {
        viewController.view.layoutIfNeeded()
        if renderedValue == value { break }
        try? await Task.sleep(for: .milliseconds(10))
      }
      #expect(renderedValue == value)
    }
  }
}
