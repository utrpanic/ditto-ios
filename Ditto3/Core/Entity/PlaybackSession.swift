import Foundation

public struct PlaybackSession: Equatable, Sendable {
  public let episode: Episode
  public let position: TimeInterval
  public let updatedAt: Date

  public init(
    episode: Episode,
    position: TimeInterval,
    updatedAt: Date
  ) {
    self.episode = episode
    self.position = position
    self.updatedAt = updatedAt
  }
}
