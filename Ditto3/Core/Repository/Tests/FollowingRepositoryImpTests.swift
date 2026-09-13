import Entity
import Foundation
import PlatformTestSupport
@testable import RepositoryImp
import Testing

struct FollowingRepositoryImpTests {
  @Test
  func fetchReturnsEmptyWhenNothingIsStored() async throws {
    let repository = FollowingRepositoryImp(userDefaults: UserDefaultsMock())

    let podcasts = try await repository.fetchFollowedPodcasts()

    #expect(podcasts.isEmpty)
  }

  @Test
  func followPersistsFullPodcastSnapshot() async throws {
    let userDefaults = UserDefaultsMock()
    let followedAt = Date(timeIntervalSince1970: 1_789_000_000)
    let podcast = makePodcast(id: 1, title: "Architecture Talks")
    let repository = FollowingRepositoryImp(userDefaults: userDefaults, now: { followedAt })

    try await repository.follow(podcast)

    #expect(try await repository.isFollowing(podcastID: podcast.id))
    #expect(try await repository.fetchFollowedPodcasts() == [
      FollowedPodcast(podcast: podcast, followedAt: followedAt),
    ])
    #expect(userDefaults.persistedData(forKey: "followed-podcasts") != nil)

    let restoredRepository = FollowingRepositoryImp(userDefaults: userDefaults)
    #expect(try await restoredRepository.fetchFollowedPodcasts() == [
      FollowedPodcast(podcast: podcast, followedAt: followedAt),
    ])
  }

  @Test
  func duplicateFollowIsIdempotent() async throws {
    let userDefaults = UserDefaultsMock()
    let firstFollowedAt = Date(timeIntervalSince1970: 1_789_000_000)
    let secondFollowedAt = Date(timeIntervalSince1970: 1_790_000_000)
    var currentDate = firstFollowedAt
    let repository = FollowingRepositoryImp(userDefaults: userDefaults, now: { currentDate })
    let podcast = makePodcast(id: 1, title: "Architecture Talks")

    try await repository.follow(podcast)
    let firstPayload = userDefaults.persistedData(forKey: "followed-podcasts")
    currentDate = secondFollowedAt
    try await repository.follow(podcast)

    #expect(try await repository.fetchFollowedPodcasts() == [
      FollowedPodcast(podcast: podcast, followedAt: firstFollowedAt),
    ])
    #expect(userDefaults.persistedData(forKey: "followed-podcasts") == firstPayload)
  }

  @Test
  func fetchSortsByMostRecentlyFollowed() async throws {
    let firstFollowedAt = Date(timeIntervalSince1970: 1_789_000_000)
    let secondFollowedAt = Date(timeIntervalSince1970: 1_790_000_000)
    var currentDate = firstFollowedAt
    let repository = FollowingRepositoryImp(userDefaults: UserDefaultsMock(), now: { currentDate })
    let firstPodcast = makePodcast(id: 1, title: "Architecture Talks")
    let secondPodcast = makePodcast(id: 2, title: "Swift Talks")

    try await repository.follow(firstPodcast)
    currentDate = secondFollowedAt
    try await repository.follow(secondPodcast)

    let podcasts = try await repository.fetchFollowedPodcasts()

    #expect(podcasts.map(\.podcast.id) == [secondPodcast.id, firstPodcast.id])
  }

  @Test
  func unfollowRemovesPersistedPodcast() async throws {
    let userDefaults = UserDefaultsMock()
    let podcast = makePodcast(id: 1, title: "Architecture Talks")
    let repository = FollowingRepositoryImp(userDefaults: userDefaults)
    try await repository.follow(podcast)

    try await repository.unfollow(podcastID: podcast.id)

    #expect(!(try await repository.isFollowing(podcastID: podcast.id)))
    #expect(try await repository.fetchFollowedPodcasts().isEmpty)

    let restoredRepository = FollowingRepositoryImp(userDefaults: userDefaults)
    #expect(try await restoredRepository.fetchFollowedPodcasts().isEmpty)
  }

  @Test
  func changesEmitsAfterFollowAndUnfollow() async throws {
    let podcast = makePodcast(id: 1, title: "Architecture Talks")
    let repository = FollowingRepositoryImp(userDefaults: UserDefaultsMock())
    let stream = await repository.changes()
    var iterator = stream.makeAsyncIterator()

    try await repository.follow(podcast)
    let followChange: Void? = await iterator.next()
    try await repository.unfollow(podcastID: podcast.id)
    let unfollowChange: Void? = await iterator.next()

    #expect(followChange != nil)
    #expect(unfollowChange != nil)
  }

  @Test
  func invalidPayloadFailsGracefully() async throws {
    let userDefaults = UserDefaultsMock()
    let repository = FollowingRepositoryImp(userDefaults: userDefaults)

    userDefaults.stubData(Data("not-json".utf8), forKey: "followed-podcasts")
    #expect(try await repository.fetchFollowedPodcasts().isEmpty)

    userDefaults.stubData(Data(#"{"version":2,"items":[]}"#.utf8), forKey: "followed-podcasts")
    #expect(try await repository.fetchFollowedPodcasts().isEmpty)
  }
}

private func makePodcast(id: Int, title: String) -> Podcast {
  Podcast(
    id: PodcastID(id),
    title: title,
    author: "Ditto",
    artworkURL: URL(string: "https://example.com/artwork/\(id).png"),
    feedURL: URL(string: "https://example.com/feed/\(id).xml"),
    summary: "A podcast about architecture."
  )
}
