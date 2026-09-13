import Entity
import Platform
import PlatformTestSupport
@testable import Repository
@testable import RepositoryImp
import Testing

struct FollowingRepositoryImpTests {
  @Test
  func fetchReturnsEmptySetWhenNoFollowingIsStored() {
    let userDefaults = UserDefaultsMock()
    let repository = FollowingRepositoryImp(userDefaults: userDefaults)

    #expect(repository.fetchFollowedPodcastIDs().isEmpty)
    #expect(userDefaults.setReadCount(forKey: "followed-podcast-ids") == 1)
  }

  @Test
  func fetchUsesCachedFollowingAfterFirstLoad() {
    let userDefaults = UserDefaultsMock()
    userDefaults.stubSet(Set([PodcastID(1), PodcastID(2)]), forKey: "followed-podcast-ids")
    let repository = FollowingRepositoryImp(userDefaults: userDefaults)

    let firstFetch = repository.fetchFollowedPodcastIDs()
    userDefaults.stubSet(Set([PodcastID(3)]), forKey: "followed-podcast-ids")
    let secondFetch = repository.fetchFollowedPodcastIDs()

    #expect(firstFetch == Set([PodcastID(1), PodcastID(2)]))
    #expect(secondFetch == Set([PodcastID(1), PodcastID(2)]))
    #expect(userDefaults.setReadCount(forKey: "followed-podcast-ids") == 1)
  }

  @Test
  func followPersistsUpdatedFollowing() {
    let userDefaults = UserDefaultsMock()
    userDefaults.stubSet(Set([PodcastID(1)]), forKey: "followed-podcast-ids")
    let repository = FollowingRepositoryImp(userDefaults: userDefaults)

    repository.follow(podcastID: PodcastID(2))

    #expect(repository.fetchFollowedPodcastIDs() == Set([PodcastID(1), PodcastID(2)]))
    #expect(repository.isFollowing(podcastID: PodcastID(2)))
    #expect(userDefaults.persistedSet(forKey: "followed-podcast-ids") == Set([PodcastID(1), PodcastID(2)]))
  }

  @Test
  func unfollowPersistsUpdatedFollowing() {
    let userDefaults = UserDefaultsMock()
    userDefaults.stubSet(Set([PodcastID(1), PodcastID(2)]), forKey: "followed-podcast-ids")
    let repository = FollowingRepositoryImp(userDefaults: userDefaults)

    repository.unfollow(podcastID: PodcastID(1))

    #expect(repository.fetchFollowedPodcastIDs() == Set([PodcastID(2)]))
    #expect(!repository.isFollowing(podcastID: PodcastID(1)))
    #expect(userDefaults.persistedSet(forKey: "followed-podcast-ids") == Set([PodcastID(2)]))
  }
}
