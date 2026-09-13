enum MainTab: Equatable {
  case discover
  case latest
  case library
  case search
}

struct MainState: Equatable {
  var selectedTab: MainTab = .discover
}
