import Entity
import Playback

struct PlayerState: Equatable {
  var playback: PlaybackState = .idle
  var isExpanded = false

  var session: PlaybackSession? {
    switch playback {
    case .idle:
      nil
    case .loading(let session), .paused(let session), .playing(let session):
      session
    case .failed(let session, _):
      session
    }
  }

  var isPlaying: Bool {
    if case .playing = playback { return true }
    return false
  }

  var isLoading: Bool {
    if case .loading = playback { return true }
    return false
  }

  var failureMessage: String? {
    if case .failed(_, let message) = playback { return message }
    return nil
  }
}
