import Entity

enum SearchTab: String, CaseIterable, Hashable, Identifiable {
  case podcast = "Podcast"
  case episode = "Episode"

  var id: Self { self }
}

struct SearchState: Equatable {
  var selectedTab: SearchTab = .podcast
  var query = ""
  var result: SearchResultState = .idle
}

enum SearchResultState: Equatable {
  case idle
  case loading(query: String)
  case podcasts([Podcast])
  case episodes([Episode])
  case failed(query: String, message: String)
}
