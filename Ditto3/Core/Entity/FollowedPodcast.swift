import Foundation

public struct FollowedPodcast: Equatable, Sendable {
  public let podcast: Podcast
  public let followedAt: Date

  public init(podcast: Podcast, followedAt: Date) {
    self.podcast = podcast
    self.followedAt = followedAt
  }
}
