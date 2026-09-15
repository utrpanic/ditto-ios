import AVFoundation
import Foundation

@MainActor
public protocol AVPlayerProtocol: AnyObject {
  var playbackCurrentTime: TimeInterval { get }
  func load(url: URL)
  func play()
  func pause()
  func seek(to position: TimeInterval) async
  func addPeriodicTimeObserver(_ handler: @escaping (TimeInterval) -> Void) -> Any
  func removeTimeObserver(_ observer: Any)
}

extension AVPlayer: AVPlayerProtocol {
  public var playbackCurrentTime: TimeInterval {
    let seconds = currentTime().seconds
    return seconds.isFinite ? seconds : 0
  }

  public func load(url: URL) {
    replaceCurrentItem(with: AVPlayerItem(url: url))
  }

  public func seek(to position: TimeInterval) async {
    let time = CMTime(seconds: position, preferredTimescale: 600)
    await withCheckedContinuation { continuation in
      seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
        continuation.resume()
      }
    }
  }

  public func addPeriodicTimeObserver(_ handler: @escaping (TimeInterval) -> Void) -> Any {
    addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
      queue: .main
    ) { time in
      let seconds = time.seconds
      handler(seconds.isFinite ? seconds : 0)
    }
  }
}
