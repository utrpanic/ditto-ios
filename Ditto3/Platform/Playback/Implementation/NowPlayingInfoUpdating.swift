import Entity
import MediaPlayer
import Playback

@MainActor
protocol NowPlayingInfoUpdating: AnyObject {
  func update(_ state: PlaybackState)
}

@MainActor
final class SystemNowPlayingInfoCenter: NowPlayingInfoUpdating {
  func update(_ state: PlaybackState) {
    guard let session = state.session else {
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
      return
    }

    var info: [String: Any] = [
      MPMediaItemPropertyTitle: session.episode.title,
      MPMediaItemPropertyAlbumTitle: session.episode.podcastTitle,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: session.position,
      MPNowPlayingInfoPropertyPlaybackRate: state.isPlaying ? 1.0 : 0.0,
    ]
    if let duration = session.episode.duration {
      info[MPMediaItemPropertyPlaybackDuration] = duration
    }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
  }
}

private extension PlaybackState {
  var session: PlaybackSession? {
    switch self {
    case .idle:
      nil
    case .loading(let session), .paused(let session), .playing(let session):
      session
    case .failed(let session, _):
      session
    }
  }

  var isPlaying: Bool {
    if case .playing = self { return true }
    return false
  }
}
