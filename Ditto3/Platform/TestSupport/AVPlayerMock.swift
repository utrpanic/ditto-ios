import Foundation
import Platform

@MainActor
public final class AVPlayerMock: AVPlayerProtocol {
  public var playbackCurrentTime: TimeInterval = 0
  public private(set) var loadedURL: URL?
  public private(set) var playCallCount = 0
  public private(set) var pauseCallCount = 0
  public private(set) var seekPositions: [TimeInterval] = []

  private var timeHandler: ((TimeInterval) -> Void)?
  private var playbackEndHandler: (() -> Void)?

  public init() {}

  public func load(url: URL) {
    loadedURL = url
    playbackCurrentTime = 0
  }

  public func play() {
    playCallCount += 1
  }

  public func pause() {
    pauseCallCount += 1
  }

  public func seek(to position: TimeInterval) async {
    seekPositions.append(position)
    playbackCurrentTime = position
  }

  public func observePlaybackEnd(_ handler: @escaping @MainActor () -> Void) -> Any {
    playbackEndHandler = handler
    return NSObject()
  }

  public func removePlaybackEndObserver(_ observer: Any) {
    playbackEndHandler = nil
  }

  public func addPeriodicTimeObserver(_ handler: @escaping (TimeInterval) -> Void) -> Any {
    timeHandler = handler
    return NSObject()
  }

  public func removeTimeObserver(_ observer: Any) {
    timeHandler = nil
  }

  public func emitTime(_ position: TimeInterval) {
    playbackCurrentTime = position
    timeHandler?(position)
  }

  public func emitPlaybackEnd() {
    playbackEndHandler?()
  }
}
