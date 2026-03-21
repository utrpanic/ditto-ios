import Entity

enum TopPodcastsState {
  case none
  case loading
  case loaded([Podcast])
  case failed(Error)
}
