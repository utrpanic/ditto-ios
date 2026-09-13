import Entity

public protocol FollowingRepository {
  func fetchFollowedPodcastIDs() -> Set<PodcastID>
  func isFollowing(podcastID: PodcastID) -> Bool
  func follow(podcastID: PodcastID)
  func unfollow(podcastID: PodcastID)
}
