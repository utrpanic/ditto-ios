import Entity

public protocol FollowingRepository: Sendable {
  func fetchFollowedPodcasts() async throws -> [FollowedPodcast]
  func isFollowing(podcastID: PodcastID) async throws -> Bool
  func follow(_ podcast: Podcast) async throws
  func unfollow(podcastID: PodcastID) async throws
  func changes() async -> AsyncStream<Void>
}
