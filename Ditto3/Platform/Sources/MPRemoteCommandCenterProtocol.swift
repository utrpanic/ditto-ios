import Foundation
import MediaPlayer

@MainActor
public protocol MPRemoteCommandCenterProtocol: AnyObject {
  func configurePlaybackCommands(
    backwardInterval: TimeInterval,
    forwardInterval: TimeInterval,
    play: @escaping () -> Void,
    pause: @escaping () -> Void,
    seek: @escaping (TimeInterval) -> Void,
    skipBackward: @escaping () -> Void,
    skipForward: @escaping () -> Void
  ) -> () -> Void
}

extension MPRemoteCommandCenter: MPRemoteCommandCenterProtocol {
  public func configurePlaybackCommands(
    backwardInterval: TimeInterval,
    forwardInterval: TimeInterval,
    play: @escaping () -> Void,
    pause: @escaping () -> Void,
    seek: @escaping (TimeInterval) -> Void,
    skipBackward: @escaping () -> Void,
    skipForward: @escaping () -> Void
  ) -> () -> Void {
    playCommand.isEnabled = true
    let playTarget = playCommand.addTarget { _ in
      Task { @MainActor in play() }
      return .success
    }

    pauseCommand.isEnabled = true
    let pauseTarget = pauseCommand.addTarget { _ in
      Task { @MainActor in pause() }
      return .success
    }

    changePlaybackPositionCommand.isEnabled = true
    let seekTarget = changePlaybackPositionCommand.addTarget { event in
      guard let event = event as? MPChangePlaybackPositionCommandEvent else {
        return .commandFailed
      }
      Task { @MainActor in seek(event.positionTime) }
      return .success
    }

    skipBackwardCommand.isEnabled = true
    skipBackwardCommand.preferredIntervals = [NSNumber(value: backwardInterval)]
    let backwardTarget = skipBackwardCommand.addTarget { _ in
      Task { @MainActor in skipBackward() }
      return .success
    }

    skipForwardCommand.isEnabled = true
    skipForwardCommand.preferredIntervals = [NSNumber(value: forwardInterval)]
    let forwardTarget = skipForwardCommand.addTarget { _ in
      Task { @MainActor in skipForward() }
      return .success
    }

    return { [weak self] in
      guard let self else { return }
      playCommand.removeTarget(playTarget)
      pauseCommand.removeTarget(pauseTarget)
      changePlaybackPositionCommand.removeTarget(seekTarget)
      skipBackwardCommand.removeTarget(backwardTarget)
      skipForwardCommand.removeTarget(forwardTarget)
      playCommand.isEnabled = false
      pauseCommand.isEnabled = false
      changePlaybackPositionCommand.isEnabled = false
      skipBackwardCommand.isEnabled = false
      skipForwardCommand.isEnabled = false
    }
  }
}
