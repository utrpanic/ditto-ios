import AVFoundation
import Foundation

@MainActor
protocol AudioPlayerControlling: AnyObject {
  var currentTime: TimeInterval { get }
  func load(url: URL)
  func play()
  func pause()
  func seek(to position: TimeInterval) async
  func addPeriodicTimeObserver(_ handler: @escaping (TimeInterval) -> Void) -> Any
  func removeTimeObserver(_ observer: Any)
}

@MainActor
final class AVPlayerAdapter: AudioPlayerControlling {
  private let player = AVPlayer()

  var currentTime: TimeInterval {
    let seconds = player.currentTime().seconds
    return seconds.isFinite ? seconds : 0
  }

  func load(url: URL) {
    player.replaceCurrentItem(with: AVPlayerItem(url: url))
  }

  func play() {
    player.play()
  }

  func pause() {
    player.pause()
  }

  func seek(to position: TimeInterval) async {
    let time = CMTime(seconds: position, preferredTimescale: 600)
    await withCheckedContinuation { continuation in
      player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
        continuation.resume()
      }
    }
  }

  func addPeriodicTimeObserver(_ handler: @escaping (TimeInterval) -> Void) -> Any {
    player.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
      queue: .main
    ) { time in
      let seconds = time.seconds
      handler(seconds.isFinite ? seconds : 0)
    }
  }

  func removeTimeObserver(_ observer: Any) {
    player.removeTimeObserver(observer)
  }
}
