import Entity

enum LatestState: Equatable {
  case loading
  case loaded(episodes: [Episode], failedPodcastCount: Int)
  case failed(message: String)
}
