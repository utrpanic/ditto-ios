import Foundation
import MediaPlayer

@MainActor
protocol RemoteCommandConfiguring: AnyObject {
  func configure(
    play: @escaping () -> Void,
    pause: @escaping () -> Void,
    seek: @escaping (TimeInterval) -> Void,
    skipBackward: @escaping () -> Void,
    skipForward: @escaping () -> Void
  )
  func reset()
}

@MainActor
final class SystemRemoteCommandCenter: RemoteCommandConfiguring {
  private let commandCenter = MPRemoteCommandCenter.shared()
  private var targets: [(command: MPRemoteCommand, target: Any)] = []

  func configure(
    play: @escaping () -> Void,
    pause: @escaping () -> Void,
    seek: @escaping (TimeInterval) -> Void,
    skipBackward: @escaping () -> Void,
    skipForward: @escaping () -> Void
  ) {
    reset()

    commandCenter.playCommand.isEnabled = true
    addTarget(to: commandCenter.playCommand) { _ in
      Task { @MainActor in play() }
      return .success
    }
    commandCenter.pauseCommand.isEnabled = true
    addTarget(to: commandCenter.pauseCommand) { _ in
      Task { @MainActor in pause() }
      return .success
    }
    commandCenter.changePlaybackPositionCommand.isEnabled = true
    addTarget(to: commandCenter.changePlaybackPositionCommand) { event in
      guard let event = event as? MPChangePlaybackPositionCommandEvent else {
        return .commandFailed
      }
      Task { @MainActor in seek(event.positionTime) }
      return .success
    }

    commandCenter.skipBackwardCommand.isEnabled = true
    commandCenter.skipBackwardCommand.preferredIntervals = [
      NSNumber(value: AVPlayerPlaybackController.backwardInterval),
    ]
    addTarget(to: commandCenter.skipBackwardCommand) { _ in
      Task { @MainActor in skipBackward() }
      return .success
    }

    commandCenter.skipForwardCommand.isEnabled = true
    commandCenter.skipForwardCommand.preferredIntervals = [
      NSNumber(value: AVPlayerPlaybackController.forwardInterval),
    ]
    addTarget(to: commandCenter.skipForwardCommand) { _ in
      Task { @MainActor in skipForward() }
      return .success
    }
  }

  func reset() {
    for (command, target) in targets {
      command.removeTarget(target)
    }
    targets.removeAll()
    commandCenter.playCommand.isEnabled = false
    commandCenter.pauseCommand.isEnabled = false
    commandCenter.changePlaybackPositionCommand.isEnabled = false
    commandCenter.skipBackwardCommand.isEnabled = false
    commandCenter.skipForwardCommand.isEnabled = false
  }

  private func addTarget(
    to command: MPRemoteCommand,
    handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
  ) {
    let target = command.addTarget(handler: handler)
    targets.append((command, target))
  }
}
