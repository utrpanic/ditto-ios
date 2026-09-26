import Entity
import Foundation
import PlatformTestSupport
import Testing
@testable import RepositoryImp

struct PlaybackQueueRepositoryImpTests {
  @Test
  func fetchReturnsEmptyWhenNothingIsStored() async throws {
    let repository = PlaybackQueueRepositoryImp(userDefaults: UserDefaultsMock())

    #expect(try await repository.fetchQueue().isEmpty)
  }

  @Test
  func playNextPersistsFullEpisodeSnapshotInQueueOrder() async throws {
    let userDefaults = UserDefaultsMock()
    let enqueuedAt = Date(timeIntervalSince1970: 1_789_000_000)
    let repository = PlaybackQueueRepositoryImp(userDefaults: userDefaults, now: { enqueuedAt })
    let firstEpisode = makeEpisode(id: "first")
    let secondEpisode = makeEpisode(id: "second")

    try await repository.playNext(firstEpisode)
    try await repository.playNext(secondEpisode)

    let expected = [
      QueueItem(episode: secondEpisode, enqueuedAt: enqueuedAt),
      QueueItem(episode: firstEpisode, enqueuedAt: enqueuedAt),
    ]
    #expect(try await repository.fetchQueue() == expected)
    #expect(userDefaults.persistedData(forKey: "playback-queue") != nil)

    let restoredRepository = PlaybackQueueRepositoryImp(userDefaults: userDefaults)
    #expect(try await restoredRepository.fetchQueue() == expected)
  }

  @Test
  func playNextMovesExistingEpisodeToTopWithoutDuplicating() async throws {
    let firstDate = Date(timeIntervalSince1970: 1_789_000_000)
    let secondDate = Date(timeIntervalSince1970: 1_790_000_000)
    var currentDate = firstDate
    let repository = PlaybackQueueRepositoryImp(
      userDefaults: UserDefaultsMock(),
      now: { currentDate }
    )
    let firstEpisode = makeEpisode(id: "first")
    let secondEpisode = makeEpisode(id: "second")

    try await repository.playNext(firstEpisode)
    try await repository.playNext(secondEpisode)
    currentDate = secondDate
    try await repository.playNext(firstEpisode)

    let queue = try await repository.fetchQueue()
    #expect(queue.map(\.episode.id) == [firstEpisode.id, secondEpisode.id])
    #expect(queue.count == 2)
    #expect(queue[0].enqueuedAt == secondDate)
  }

  @Test
  func addToQueueAppendsAndMovesExistingEpisodeToEnd() async throws {
    let repository = PlaybackQueueRepositoryImp(userDefaults: UserDefaultsMock())
    let firstEpisode = makeEpisode(id: "first")
    let secondEpisode = makeEpisode(id: "second")

    try await repository.addToQueue(firstEpisode)
    try await repository.addToQueue(secondEpisode)
    #expect(try await repository.fetchQueue().map(\.episode.id) == [
      firstEpisode.id, secondEpisode.id,
    ])

    try await repository.addToQueue(firstEpisode)
    #expect(try await repository.fetchQueue().map(\.episode.id) == [
      secondEpisode.id, firstEpisode.id,
    ])
    #expect(try await repository.fetchQueue().count == 2)
  }

  @Test
  func dequeueReturnsAndRemovesFirstItem() async throws {
    let userDefaults = UserDefaultsMock()
    let repository = PlaybackQueueRepositoryImp(userDefaults: userDefaults)
    let firstEpisode = makeEpisode(id: "first")
    let secondEpisode = makeEpisode(id: "second")
    try await repository.addToQueue(firstEpisode)
    try await repository.addToQueue(secondEpisode)
    let stream = await repository.changes()
    var iterator = stream.makeAsyncIterator()

    let dequeuedItem = try await repository.dequeue()
    let dequeueChange: Void? = await iterator.next()

    #expect(dequeuedItem?.episode == firstEpisode)
    #expect(dequeueChange != nil)
    #expect(try await repository.fetchQueue().map(\.episode.id) == [secondEpisode.id])
    let restoredRepository = PlaybackQueueRepositoryImp(userDefaults: userDefaults)
    #expect(try await restoredRepository.fetchQueue().map(\.episode.id) == [secondEpisode.id])
  }

  @Test
  func dequeueFromEmptyQueueDoesNotPersistOrEmitChange() async throws {
    let userDefaults = UserDefaultsMock()
    let repository = PlaybackQueueRepositoryImp(userDefaults: userDefaults)

    #expect(try await repository.dequeue() == nil)
    #expect(userDefaults.persistedData(forKey: "playback-queue") == nil)
  }

  @Test
  func moveUsesFinalDestinationIndexAndPreservesItemSnapshot() async throws {
    let repository = PlaybackQueueRepositoryImp(userDefaults: UserDefaultsMock())
    let firstEpisode = makeEpisode(id: "first")
    let secondEpisode = makeEpisode(id: "second")
    let thirdEpisode = makeEpisode(id: "third")
    try await repository.playNext(thirdEpisode)
    try await repository.playNext(secondEpisode)
    try await repository.playNext(firstEpisode)
    let originalQueue = try await repository.fetchQueue()

    try await repository.move(episodeID: firstEpisode.id, to: 2)

    let queue = try await repository.fetchQueue()
    #expect(queue.map(\.episode.id) == [secondEpisode.id, thirdEpisode.id, firstEpisode.id])
    #expect(queue[2] == originalQueue[0])

    try await repository.move(episodeID: firstEpisode.id, to: -1)
    #expect(try await repository.fetchQueue().map(\.episode.id) == [
      firstEpisode.id, secondEpisode.id, thirdEpisode.id,
    ])

    try await repository.move(episodeID: firstEpisode.id, to: 100)
    #expect(try await repository.fetchQueue().map(\.episode.id) == [
      secondEpisode.id, thirdEpisode.id, firstEpisode.id,
    ])
  }

  @Test
  func removeAndRemoveAllPersistEmptyQueue() async throws {
    let userDefaults = UserDefaultsMock()
    let repository = PlaybackQueueRepositoryImp(userDefaults: userDefaults)
    let firstEpisode = makeEpisode(id: "first")
    let secondEpisode = makeEpisode(id: "second")
    try await repository.playNext(firstEpisode)
    try await repository.playNext(secondEpisode)

    try await repository.remove(episodeID: secondEpisode.id)
    #expect(try await repository.fetchQueue().map(\.episode.id) == [firstEpisode.id])

    try await repository.removeAll()
    #expect(try await repository.fetchQueue().isEmpty)

    let restoredRepository = PlaybackQueueRepositoryImp(userDefaults: userDefaults)
    #expect(try await restoredRepository.fetchQueue().isEmpty)
  }

  @Test
  func changesEmitOnlyForActualMutations() async throws {
    let userDefaults = UserDefaultsMock()
    let repository = PlaybackQueueRepositoryImp(userDefaults: userDefaults)
    let episode = makeEpisode(id: "first")
    let stream = await repository.changes()
    var iterator = stream.makeAsyncIterator()

    try await repository.playNext(episode)
    let insertChange: Void? = await iterator.next()
    let firstPayload = userDefaults.persistedData(forKey: "playback-queue")

    try await repository.move(episodeID: episode.id, to: 0)
    try await repository.remove(episodeID: EpisodeID("missing"))
    #expect(userDefaults.persistedData(forKey: "playback-queue") == firstPayload)

    try await repository.remove(episodeID: episode.id)
    let removeChange: Void? = await iterator.next()
    let emptyPayload = userDefaults.persistedData(forKey: "playback-queue")

    try await repository.removeAll()
    #expect(userDefaults.persistedData(forKey: "playback-queue") == emptyPayload)
    #expect(insertChange != nil)
    #expect(removeChange != nil)
  }

  @Test
  func moveAndRemoveAllEmitChanges() async throws {
    let repository = PlaybackQueueRepositoryImp(userDefaults: UserDefaultsMock())
    let firstEpisode = makeEpisode(id: "first")
    let secondEpisode = makeEpisode(id: "second")
    try await repository.playNext(firstEpisode)
    try await repository.playNext(secondEpisode)
    let stream = await repository.changes()
    var iterator = stream.makeAsyncIterator()

    try await repository.move(episodeID: secondEpisode.id, to: 1)
    let moveChange: Void? = await iterator.next()
    try await repository.removeAll()
    let clearChange: Void? = await iterator.next()

    #expect(moveChange != nil)
    #expect(clearChange != nil)
    #expect(try await repository.fetchQueue().isEmpty)
  }

  @Test
  func invalidAndUnsupportedPayloadsFailGracefully() async throws {
    let userDefaults = UserDefaultsMock()
    let repository = PlaybackQueueRepositoryImp(userDefaults: userDefaults)

    userDefaults.stubData(Data("not-json".utf8), forKey: "playback-queue")
    #expect(try await repository.fetchQueue().isEmpty)

    userDefaults.stubData(Data(#"{"version":2,"items":[]}"#.utf8), forKey: "playback-queue")
    #expect(try await repository.fetchQueue().isEmpty)
  }
}

private func makeEpisode(id: String) -> Episode {
  Episode(
    id: EpisodeID(id),
    podcastID: PodcastID(42),
    podcastTitle: "Architecture Talks",
    title: "Episode \(id)",
    feedURL: URL(string: "https://example.com/feed.xml")!,
    author: "Ditto",
    artworkURL: URL(string: "https://example.com/artwork.png"),
    audioURL: URL(string: "https://example.com/\(id).mp3"),
    pageURL: URL(string: "https://example.com/\(id)"),
    description: "An architecture episode.",
    publishedAt: Date(timeIntervalSince1970: 1_788_000_000),
    duration: 3_600
  )
}
