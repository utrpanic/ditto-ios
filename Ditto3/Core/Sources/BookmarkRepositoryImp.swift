import Platform

public final class BookmarkRepositoryImp: BookmarkRepository, @unchecked Sendable {
  private let userDefaults: UserDefaultsProtocol
  private let bookmarksKey: String = "bookmarks"
  private var cachedBookmarkedPodcastIDs: Set<PodcastID>?

  public init(userDefaults: UserDefaultsProtocol) {
    self.userDefaults = userDefaults
  }

  public func fetchBookmarkedPodcastIDs() -> Set<PodcastID> {
    loadCacheIfNeeded()
    return cachedBookmarkedPodcastIDs ?? []
  }

  public func isBookmarked(podcastID: PodcastID) -> Bool {
    fetchBookmarkedPodcastIDs().contains(podcastID)
  }

  public func insertBookmark(podcastID: PodcastID) {
    loadCacheIfNeeded()
    cachedBookmarkedPodcastIDs?.insert(podcastID)
    persistCache()
  }

  public func removeBookmark(podcastID: PodcastID) {
    loadCacheIfNeeded()
    cachedBookmarkedPodcastIDs?.remove(podcastID)
    persistCache()
  }

  private func loadCacheIfNeeded() {
    guard cachedBookmarkedPodcastIDs == nil else { return }
    cachedBookmarkedPodcastIDs = userDefaults.set(forKey: bookmarksKey) ?? []
  }

  private func persistCache() {
    userDefaults.set(value: cachedBookmarkedPodcastIDs, forKey: bookmarksKey)
  }
}
