import Foundation

public struct QueueItem: Equatable, Sendable {
  public let episode: Episode
  public let enqueuedAt: Date

  public init(episode: Episode, enqueuedAt: Date) {
    self.episode = episode
    self.enqueuedAt = enqueuedAt
  }
}
