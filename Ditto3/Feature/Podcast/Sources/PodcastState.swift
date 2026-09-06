import Entity

enum PodcastState: Equatable {
  case loading(podcast: Podcast)
  case loaded(podcast: Podcast, episodes: [Episode])
  case failed(podcast: Podcast, message: String)

  var podcast: Podcast {
    switch self {
    case .loading(let podcast), .loaded(let podcast, _), .failed(let podcast, _):
      podcast
    }
  }
}
