import Entity

struct EpisodeState: Equatable {
  let episode: Episode
  var queueMessage: String? = nil
}

enum EpisodeAction {
  case play
  case playNext
  case addToQueue
}
