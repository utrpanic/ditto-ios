import Foundation

public struct KeptEpisode: Equatable, Sendable {
  public let episode: Episode
  public let keptAt: Date

  public init(episode: Episode, keptAt: Date) {
    self.episode = episode
    self.keptAt = keptAt
  }
}
