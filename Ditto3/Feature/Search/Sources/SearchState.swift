import Entity

enum SearchState: Equatable {
  case idle
  case loading(query: String)
  case loaded(query: String, podcasts: [Podcast])
  case failed(query: String, message: String)
}
