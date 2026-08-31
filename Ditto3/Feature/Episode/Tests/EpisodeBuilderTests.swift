import Entity
@testable import Episode
import Foundation
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
      author: "KeepCast",
      artworkURL: URL(string: "https://example.com/artwork.png"),
      audioURL: URL(string: "https://example.com/audio.mp3"),
      pageURL: URL(string: "https://example.com/episodes/architecture"),
      description: "An architecture experiment.",
      publishedAt: Date(timeIntervalSince1970: 1_700_000_000),
      duration: 3_600
    )
    let listener = Listener()
    let builder = EpisodeBuilder(dependency: Dependency())

    let result = builder.build(episode: episode, listener: listener)

    let viewController = try #require(result as? EpisodeViewController)
    let interactor = try #require(viewController.interactor as? EpisodeInteractor)
    #expect(interactor.store.state.episode == episode)
    #expect(interactor.listener === listener)
    #expect(interactor.router != nil)
  }
}

private struct Dependency: EpisodeDependency {}

@MainActor
private final class Listener: EpisodeListener {}
