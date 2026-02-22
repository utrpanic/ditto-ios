public protocol BookmarkRepository: Sendable {
  func fetchBookmarkedPodcastIDs() -> Set<PodcastID>
  func isBookmarked(podcastID: PodcastID) -> Bool
  func insertBookmark(podcastID: PodcastID)
  func removeBookmark(podcastID: PodcastID)
}
