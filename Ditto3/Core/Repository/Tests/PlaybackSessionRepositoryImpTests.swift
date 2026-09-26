import Entity
import Foundation
import PlatformTestSupport
import Testing
@testable import RepositoryImp

struct PlaybackSessionRepositoryImpTests {
  @Test
  func saveAndLoadPreserveTheFullSessionSnapshot() async throws {
    let userDefaults = UserDefaultsMock()
    let repository = PlaybackSessionRepositoryImp(userDefaults: userDefaults)
    let session = makeSession()

    try await repository.saveSession(session)

    #expect(userDefaults.persistedData(forKey: "playback-session") != nil)
    let restoredRepository = PlaybackSessionRepositoryImp(userDefaults: userDefaults)
    #expect(try await restoredRepository.loadSession() == session)
  }

  @Test
  func clearRemovesThePersistedSession() async throws {
    let userDefaults = UserDefaultsMock()
    let repository = PlaybackSessionRepositoryImp(userDefaults: userDefaults)
    try await repository.saveSession(makeSession())

    try await repository.clearSession()

    #expect(try await repository.loadSession() == nil)
    #expect(userDefaults.persistedData(forKey: "playback-session") == nil)
  }

  @Test
  func missingInvalidAndUnsupportedPayloadsReturnNil() async throws {
    let userDefaults = UserDefaultsMock()
    let repository = PlaybackSessionRepositoryImp(userDefaults: userDefaults)
    #expect(try await repository.loadSession() == nil)

    userDefaults.stubData(Data("not-json".utf8), forKey: "playback-session")
    #expect(try await repository.loadSession() == nil)

    let unsupportedPayload = #"{"version":2,"session":{}}"#
    userDefaults.stubData(Data(unsupportedPayload.utf8), forKey: "playback-session")
    #expect(try await repository.loadSession() == nil)
  }
}

private func makeSession() -> PlaybackSession {
  PlaybackSession(
    episode: Episode(
      id: EpisodeID("episode-id"),
      podcastID: PodcastID(42),
      podcastTitle: "Architecture Talks",
      title: "Resume Playback",
      feedURL: URL(string: "https://example.com/feed.xml")!,
      author: "Ditto",
      artworkURL: URL(string: "https://example.com/artwork.png"),
      audioURL: URL(string: "https://example.com/episode.mp3"),
      pageURL: URL(string: "https://example.com/episode"),
      description: "A persisted playback session.",
      publishedAt: Date(timeIntervalSince1970: 1_788_000_000),
      duration: 3_600
    ),
    position: 421,
    updatedAt: Date(timeIntervalSince1970: 1_789_000_000)
  )
}
