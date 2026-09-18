import Entity
@testable import Episode
import Foundation
import Playback
import Repository
import Testing

struct EpisodeBuilderTests {
  @MainActor
  @Test
  func buildPassesEpisodeAndListenerToTheRIB() throws {
    let feedURL = try #require(URL(string: "https://example.com/feed.xml"))
    let episode = Episode(
      id: EpisodeID("episode-guid"),
      podcastID: PodcastID(42),
      podcastTitle: "Architecture Talks",
      title: "View-controller-centered RIBs",
      feedURL: feedURL,
      author: "Ditto",
      artworkURL: URL(string: "https://example.com/artwork.png"),
      audioURL: URL(string: "https://example.com/audio.mp3"),
      pageURL: URL(string: "https://example.com/episodes/architecture"),
      description: "An architecture experiment.",
      publishedAt: Date(timeIntervalSince1970: 1_700_000_000),
      duration: 3_600
    )
    let listener = Listener()
    let builder = EpisodeBuilder(
      dependency: Dependency(
        playbackController: PlaybackControllerSpy(),
        playbackQueueRepository: PlaybackQueueRepositorySpy()
      )
    )

    let result = builder.build(episode: episode, listener: listener)

    let viewController = try #require(result as? EpisodeViewController)
    let interactor = try #require(viewController.interactor as? EpisodeInteractor)
    #expect(interactor.store.state.episode == episode)
    #expect(interactor.listener === listener)
    #expect(interactor.router != nil)
  }

  @MainActor
  @Test
  func playActionStartsSelectedEpisode() async {
    let episode = Episode(
      id: EpisodeID("episode-guid"),
      podcastTitle: "Architecture Talks",
      title: "View-controller-centered RIBs",
      feedURL: URL(string: "https://example.com/feed.xml")!,
      audioURL: URL(string: "https://example.com/audio.mp3")
    )
    let playbackController = PlaybackControllerSpy()
    let dependency = Dependency(
      playbackController: playbackController,
      playbackQueueRepository: PlaybackQueueRepositorySpy()
    )
    let interactor = EpisodeInteractor(episode: episode, dependency: dependency)

    interactor.sendAction(.play)

    await waitUntil { playbackController.playedEpisode == episode }
    #expect(playbackController.playedEpisode == episode)
  }

  @MainActor
  @Test
  func playNextStartsEpisodeWhenNothingIsPlaying() async {
    let episode = makeEpisode()
    let playbackController = PlaybackControllerSpy(initialState: .idle)
    let queueRepository = PlaybackQueueRepositorySpy()
    let interactor = EpisodeInteractor(
      episode: episode,
      dependency: Dependency(
        playbackController: playbackController,
        playbackQueueRepository: queueRepository
      )
    )

    interactor.sendAction(.playNext)

    await waitUntil { playbackController.playedEpisode == episode }
    #expect(await queueRepository.queuedEpisodes().isEmpty)
    #expect(interactor.store.state.queueMessage == "Playing now")
  }

  @MainActor
  @Test
  func playNextQueuesEpisodeWhenSessionExists() async {
    let currentEpisode = makeEpisode(id: "current")
    let nextEpisode = makeEpisode(id: "next")
    let playbackController = PlaybackControllerSpy(
      initialState: .playing(PlaybackSession(
        episode: currentEpisode,
        position: 10,
        updatedAt: Date(timeIntervalSince1970: 1_000)
      ))
    )
    let queueRepository = PlaybackQueueRepositorySpy()
    let interactor = EpisodeInteractor(
      episode: nextEpisode,
      dependency: Dependency(
        playbackController: playbackController,
        playbackQueueRepository: queueRepository
      )
    )

    interactor.sendAction(.playNext)

    await waitUntil { await queueRepository.queuedEpisodes() == [nextEpisode] }
    #expect(playbackController.playedEpisode == nil)
    #expect(interactor.store.state.queueMessage == "Will play next")
  }

  @MainActor
  @Test
  func addToQueueAppendsEpisodeWithoutStartingPlayback() async {
    let episode = makeEpisode(id: "queued")
    let playbackController = PlaybackControllerSpy(initialState: .idle)
    let queueRepository = PlaybackQueueRepositorySpy()
    let interactor = EpisodeInteractor(
      episode: episode,
      dependency: Dependency(
        playbackController: playbackController,
        playbackQueueRepository: queueRepository
      )
    )

    interactor.sendAction(.addToQueue)

    await waitUntil { await queueRepository.queuedEpisodes() == [episode] }
    #expect(playbackController.playedEpisode == nil)
    #expect(interactor.store.state.queueMessage == "Added to Queue")
  }
}

private struct Dependency: EpisodeDependency {
  let playbackController: PlaybackControlling
  let playbackQueueRepository: PlaybackQueueRepository
}

@MainActor
private final class Listener: EpisodeListener {}

@MainActor
private final class PlaybackControllerSpy: PlaybackControlling {
  let initialState: PlaybackState
  private(set) var playedEpisode: Entity.Episode?

  init(initialState: PlaybackState = .idle) {
    self.initialState = initialState
  }

  func play(_ episode: Entity.Episode) async {
    playedEpisode = episode
  }

  func play() {}
  func pause() {}
  func seek(to position: TimeInterval) async {}
  func skipBackward() {}
  func skipForward() {}
  func stateChanges() -> AsyncStream<PlaybackState> {
    AsyncStream { continuation in
      continuation.yield(initialState)
    }
  }
}

private actor PlaybackQueueRepositorySpy: PlaybackQueueRepository {
  private var episodes: [Entity.Episode] = []

  func fetchQueue() -> [QueueItem] { [] }
  func playNext(_ episode: Entity.Episode) { episodes.insert(episode, at: 0) }
  func addToQueue(_ episode: Entity.Episode) { episodes.append(episode) }
  func move(episodeID: EpisodeID, to index: Int) {}
  func remove(episodeID: EpisodeID) {}
  func removeAll() { episodes = [] }
  func changes() -> AsyncStream<Void> { AsyncStream { _ in } }
  func queuedEpisodes() -> [Entity.Episode] { episodes }
}

private func makeEpisode(id: String = "episode-guid") -> Entity.Episode {
  Entity.Episode(
    id: EpisodeID(id),
    podcastTitle: "Architecture Talks",
    title: "View-controller-centered RIBs",
    feedURL: URL(string: "https://example.com/feed.xml")!,
    audioURL: URL(string: "https://example.com/audio.mp3")
  )
}

@MainActor
private func waitUntil(_ condition: () async -> Bool) async {
  for _ in 0..<1_000 {
    guard !(await condition()) else { return }
    await Task.yield()
  }
}
