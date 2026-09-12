import Entity
import Foundation
import PlatformTestSupport
@testable import RepositoryImp
import Testing

struct KeepRepositoryImpTests {
  @Test
  func fetchReturnsEmptyWhenNothingIsStored() async throws {
    let repository = KeepRepositoryImp(userDefaults: UserDefaultsMock())

    let episodes = try await repository.fetchKeptEpisodes()

    #expect(episodes.isEmpty)
  }

  @Test
  func keepPersistsFullEpisodeSnapshot() async throws {
    let userDefaults = UserDefaultsMock()
    let keptAt = Date(timeIntervalSince1970: 1_789_000_000)
    let repository = KeepRepositoryImp(userDefaults: userDefaults, now: { keptAt })
    let episode = makeEpisode(id: "episode-1", title: "Episode One")

    try await repository.keep(episode)

    #expect(try await repository.isKept(episodeID: episode.id))
    #expect(try await repository.fetchKeptEpisodes() == [
      KeptEpisode(episode: episode, keptAt: keptAt),
    ])
    #expect(userDefaults.persistedData(forKey: "kept-episodes") != nil)
  }

  @Test
  func duplicateKeepIsIdempotent() async throws {
    let userDefaults = UserDefaultsMock()
    let firstKeptAt = Date(timeIntervalSince1970: 1_789_000_000)
    let secondKeptAt = Date(timeIntervalSince1970: 1_790_000_000)
    var currentDate = firstKeptAt
    let repository = KeepRepositoryImp(userDefaults: userDefaults, now: { currentDate })
    let episode = makeEpisode(id: "episode-1", title: "Episode One")

    try await repository.keep(episode)
    currentDate = secondKeptAt
    try await repository.keep(episode)

    #expect(try await repository.fetchKeptEpisodes() == [
      KeptEpisode(episode: episode, keptAt: firstKeptAt),
    ])
  }

  @Test
  func fetchSortsByMostRecentlyKept() async throws {
    let firstKeptAt = Date(timeIntervalSince1970: 1_789_000_000)
    let secondKeptAt = Date(timeIntervalSince1970: 1_790_000_000)
    var currentDate = firstKeptAt
    let repository = KeepRepositoryImp(userDefaults: UserDefaultsMock(), now: { currentDate })
    let firstEpisode = makeEpisode(id: "episode-1", title: "Episode One")
    let secondEpisode = makeEpisode(id: "episode-2", title: "Episode Two")

    try await repository.keep(firstEpisode)
    currentDate = secondKeptAt
    try await repository.keep(secondEpisode)

    let episodes = try await repository.fetchKeptEpisodes()

    #expect(episodes.map(\.episode.id) == [secondEpisode.id, firstEpisode.id])
  }

  @Test
  func unkeepRemovesPersistedEpisode() async throws {
    let repository = KeepRepositoryImp(userDefaults: UserDefaultsMock())
    let episode = makeEpisode(id: "episode-1", title: "Episode One")
    try await repository.keep(episode)

    try await repository.unkeep(episodeID: episode.id)

    #expect(!(try await repository.isKept(episodeID: episode.id)))
    #expect(try await repository.fetchKeptEpisodes().isEmpty)
  }

  @Test
  func corruptOrUnsupportedDataReturnsEmpty() async throws {
    let userDefaults = UserDefaultsMock()
    let repository = KeepRepositoryImp(userDefaults: userDefaults)

    userDefaults.stubData(Data("not-json".utf8), forKey: "kept-episodes")
    #expect(try await repository.fetchKeptEpisodes().isEmpty)

    userDefaults.stubData(Data(#"{"version":2,"items":[]}"#.utf8), forKey: "kept-episodes")
    #expect(try await repository.fetchKeptEpisodes().isEmpty)
  }
}

private func makeEpisode(id: String, title: String) -> Episode {
  Episode(
    id: EpisodeID(id),
    podcastID: PodcastID(42),
    podcastTitle: "Architecture Talks",
    title: title,
    feedURL: URL(string: "https://example.com/feed.xml")!,
    author: "KeepCast",
    artworkURL: URL(string: "https://example.com/artwork.png"),
    audioURL: URL(string: "https://example.com/episode.mp3"),
    pageURL: URL(string: "https://example.com/episode"),
    description: "Episode description",
    publishedAt: Date(timeIntervalSince1970: 1_788_000_000),
    duration: 3_723
  )
}
