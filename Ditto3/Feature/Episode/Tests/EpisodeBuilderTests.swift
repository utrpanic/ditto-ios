import Entity
@testable import Episode
import Foundation
import Playback
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
      dependency: Dependency(playbackController: PlaybackControllerSpy())
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
    let dependency = Dependency(playbackController: playbackController)
    let interactor = EpisodeInteractor(episode: episode, dependency: dependency)

    interactor.sendAction(.play)

    await waitUntil { playbackController.playedEpisode == episode }
    #expect(playbackController.playedEpisode == episode)
  }
}

private struct Dependency: EpisodeDependency {
  let playbackController: PlaybackControlling
}

@MainActor
private final class Listener: EpisodeListener {}

@MainActor
private final class PlaybackControllerSpy: PlaybackControlling {
  private(set) var playedEpisode: Entity.Episode?

  func play(_ episode: Entity.Episode) async {
    playedEpisode = episode
  }

  func play() {}
  func pause() {}
  func seek(to position: TimeInterval) async {}
  func skipBackward() {}
  func skipForward() {}
  func stateChanges() -> AsyncStream<PlaybackState> { AsyncStream { _ in } }
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async {
  for _ in 0..<1_000 {
    guard !condition() else { return }
    await Task.yield()
  }
}
