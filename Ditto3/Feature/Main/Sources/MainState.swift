enum MainTab: Equatable {
  case topPodcasts
  case new
  case bookmarks
  case search
}

struct MainState: Equatable {
  var selectedTab: MainTab = .topPodcasts
}
