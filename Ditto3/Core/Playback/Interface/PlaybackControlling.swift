import Entity
import Foundation

@MainActor
public protocol PlaybackControlling: AnyObject {
  func play(_ episode: Episode) async
  func play()
  func pause()
  func seek(to position: TimeInterval) async
  func skipBackward()
  func skipForward()
  func stateChanges() -> AsyncStream<PlaybackState>
}
