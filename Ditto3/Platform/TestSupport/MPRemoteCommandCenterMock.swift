import Foundation
import Platform

@MainActor
public final class MPRemoteCommandCenterMock: MPRemoteCommandCenterProtocol {
  public private(set) var backwardInterval: TimeInterval?
  public private(set) var forwardInterval: TimeInterval?
  public private(set) var resetCallCount = 0

  private var play: (() -> Void)?
  private var pause: (() -> Void)?
  private var seek: ((TimeInterval) -> Void)?
  private var skipBackward: (() -> Void)?
  private var skipForward: (() -> Void)?

  public init() {}

  public func configurePlaybackCommands(
    backwardInterval: TimeInterval,
    forwardInterval: TimeInterval,
    play: @escaping () -> Void,
    pause: @escaping () -> Void,
    seek: @escaping (TimeInterval) -> Void,
    skipBackward: @escaping () -> Void,
    skipForward: @escaping () -> Void
  ) -> () -> Void {
    self.backwardInterval = backwardInterval
    self.forwardInterval = forwardInterval
    self.play = play
    self.pause = pause
    self.seek = seek
    self.skipBackward = skipBackward
    self.skipForward = skipForward

    return { [weak self] in
      self?.resetCallCount += 1
    }
  }

  public func sendPlay() { play?() }
  public func sendPause() { pause?() }
  public func sendSeek(to position: TimeInterval) { seek?(position) }
  public func sendSkipBackward() { skipBackward?() }
  public func sendSkipForward() { skipForward?() }
}
