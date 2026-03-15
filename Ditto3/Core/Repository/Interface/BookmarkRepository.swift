import Entity

public protocol BookmarkRepository {
  func fetchBookmarkedPodcastIDs() -> Set<PodcastID>
  func isBookmarked(podcastID: PodcastID) -> Bool
  func insertBookmark(podcastID: PodcastID)
  func removeBookmark(podcastID: PodcastID)
}
