import Entity
import Foundation

@MainActor
public protocol PlaybackControlling: AnyObject {
  func play(_ episode: Episode) async
  func restore(_ session: PlaybackSession) async
  func play() async
  func pause()
  func seek(to position: TimeInterval) async
  func skipBackward()
  func skipForward()
  func stateChanges() -> AsyncStream<PlaybackState>
  func completionEvents() -> AsyncStream<PlaybackSession>
}
