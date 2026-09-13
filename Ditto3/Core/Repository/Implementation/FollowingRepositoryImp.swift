import Entity
import Platform
import Repository

public final class FollowingRepositoryImp: FollowingRepository {
  private let userDefaults: UserDefaultsProtocol
  private let followedPodcastIDsKey = "followed-podcast-ids"
  private var cachedFollowedPodcastIDs: Set<PodcastID>?

  public init(userDefaults: UserDefaultsProtocol) {
    self.userDefaults = userDefaults
  }

  public func fetchFollowedPodcastIDs() -> Set<PodcastID> {
    loadCacheIfNeeded()
    return cachedFollowedPodcastIDs ?? []
  }

  public func isFollowing(podcastID: PodcastID) -> Bool {
    fetchFollowedPodcastIDs().contains(podcastID)
  }

  public func follow(podcastID: PodcastID) {
    loadCacheIfNeeded()
    cachedFollowedPodcastIDs?.insert(podcastID)
    persistCache()
  }

  public func unfollow(podcastID: PodcastID) {
    loadCacheIfNeeded()
    cachedFollowedPodcastIDs?.remove(podcastID)
    persistCache()
  }

  private func loadCacheIfNeeded() {
    guard cachedFollowedPodcastIDs == nil else { return }
    cachedFollowedPodcastIDs = userDefaults.set(forKey: followedPodcastIDsKey) ?? []
  }

  private func persistCache() {
    userDefaults.set(value: cachedFollowedPodcastIDs, forKey: followedPodcastIDsKey)
  }
}
