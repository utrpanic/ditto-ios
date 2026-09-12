import Entity

struct EpisodeState: Equatable {
  let episode: Episode
  var isKept: Bool?
  var isUpdatingKeep = false
  var keepErrorMessage: String?
}
