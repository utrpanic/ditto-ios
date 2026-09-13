import Entity

public enum PlaybackState: Equatable, Sendable {
  case idle
  case loading(PlaybackSession)
  case paused(PlaybackSession)
  case playing(PlaybackSession)
  case failed(PlaybackSession?, message: String)
}
