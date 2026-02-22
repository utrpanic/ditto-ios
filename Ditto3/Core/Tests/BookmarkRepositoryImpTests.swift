import Testing
import Platform
import PlatformTestSupport
@testable import Core

struct BookmarkRepositoryImpTests {
  @Test
  func fetchReturnsEmptySetWhenNoBookmarksAreStored() {
    let userDefaults = UserDefaultsMock()
    let repository = BookmarkRepositoryImp(userDefaults: userDefaults)

    #expect(repository.fetchBookmarkedPodcastIDs().isEmpty)
    #expect(userDefaults.setReadCount(forKey: "bookmarks") == 1)
  }

  @Test
  func fetchUsesCachedBookmarksAfterFirstLoad() {
    let userDefaults = UserDefaultsMock()
    userDefaults.stubSet(Set([PodcastID(1), PodcastID(2)]), forKey: "bookmarks")
    let repository = BookmarkRepositoryImp(userDefaults: userDefaults)

    let firstFetch = repository.fetchBookmarkedPodcastIDs()
    userDefaults.stubSet(Set([PodcastID(3)]), forKey: "bookmarks")
    let secondFetch = repository.fetchBookmarkedPodcastIDs()

    #expect(firstFetch == Set([PodcastID(1), PodcastID(2)]))
    #expect(secondFetch == Set([PodcastID(1), PodcastID(2)]))
    #expect(userDefaults.setReadCount(forKey: "bookmarks") == 1)
  }

  @Test
  func insertBookmarkPersistsUpdatedBookmarks() {
    let userDefaults = UserDefaultsMock()
    userDefaults.stubSet(Set([PodcastID(1)]), forKey: "bookmarks")
    let repository = BookmarkRepositoryImp(userDefaults: userDefaults)

    repository.insertBookmark(podcastID: PodcastID(2))

    #expect(repository.fetchBookmarkedPodcastIDs() == Set([PodcastID(1), PodcastID(2)]))
    #expect(repository.isBookmarked(podcastID: PodcastID(2)))
    #expect(userDefaults.persistedSet(forKey: "bookmarks") == Set([PodcastID(1), PodcastID(2)]))
  }

  @Test
  func removeBookmarkPersistsUpdatedBookmarks() {
    let userDefaults = UserDefaultsMock()
    userDefaults.stubSet(Set([PodcastID(1), PodcastID(2)]), forKey: "bookmarks")
    let repository = BookmarkRepositoryImp(userDefaults: userDefaults)

    repository.removeBookmark(podcastID: PodcastID(1))

    #expect(repository.fetchBookmarkedPodcastIDs() == Set([PodcastID(2)]))
    #expect(!repository.isBookmarked(podcastID: PodcastID(1)))
    #expect(userDefaults.persistedSet(forKey: "bookmarks") == Set([PodcastID(2)]))
  }
}
