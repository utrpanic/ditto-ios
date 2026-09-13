import Entity

enum DiscoverState {
  case none
  case loading
  case loaded([Podcast])
  case failed(Error)
}
