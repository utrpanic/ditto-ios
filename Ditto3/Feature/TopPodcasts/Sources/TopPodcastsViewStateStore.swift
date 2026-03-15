import SwiftUI

@MainActor
final class TopPodcastsViewStateStore: ObservableObject {
  @Published var state: TopPodcastsState

  init(state: TopPodcastsState) {
    self.state = state
  }
}
