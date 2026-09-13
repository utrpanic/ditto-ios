import Entity

struct PodcastState: Equatable {
  let podcast: Podcast
  var episodes: PodcastEpisodesState = .loading
  var isFollowing: Bool?
  var isUpdatingFollowing = false
  var followingErrorMessage: String?
}

enum PodcastEpisodesState: Equatable {
  case loading
  case loaded([Episode])
  case failed(message: String)
}
