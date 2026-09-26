import Entity

enum LibraryState: Equatable {
  case loading
  case loaded([FollowedPodcast])
  case failed(message: String)
}
