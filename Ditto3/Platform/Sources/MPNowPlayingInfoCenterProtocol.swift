import Foundation
import MediaPlayer

@MainActor
public protocol MPNowPlayingInfoCenterProtocol: AnyObject {
  func update(
    title: String?,
    podcastTitle: String?,
    duration: TimeInterval?,
    position: TimeInterval?,
    isPlaying: Bool
  )
}

extension MPNowPlayingInfoCenter: MPNowPlayingInfoCenterProtocol {
  public func update(
    title: String?,
    podcastTitle: String?,
    duration: TimeInterval?,
    position: TimeInterval?,
    isPlaying: Bool
  ) {
    guard let title, let podcastTitle, let position else {
      nowPlayingInfo = nil
      return
    }

    var info: [String: Any] = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyAlbumTitle: podcastTitle,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: position,
      MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
    ]
    if let duration {
      info[MPMediaItemPropertyPlaybackDuration] = duration
    }
    nowPlayingInfo = info
  }
}
