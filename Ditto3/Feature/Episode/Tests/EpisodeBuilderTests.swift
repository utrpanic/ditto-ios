import Entity
@testable import Episode
import Foundation
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

  @MainActor
  @Test
  func activationLoadsKeepState() async {
    let repository = KeepRepositorySpy(isKept: true)
    let interactor = EpisodeInteractor(
      episode: makeEpisode(),
      dependency: Dependency(keepRepository: repository)
    )

    interactor.activate()
    await waitUntil { interactor.store.state.isKept == true }

    #expect(interactor.store.state.isKept == true)
    #expect(!interactor.store.state.isUpdatingKeep)
  }

  @MainActor
  @Test
  func toggleKeepUpdatesOptimisticallyAndPersists() async {
    let repository = KeepRepositorySpy(isKept: false)
    let episode = makeEpisode()
    let interactor = EpisodeInteractor(
      episode: episode,
      dependency: Dependency(keepRepository: repository)
    )
    interactor.activate()
    await waitUntil { interactor.store.state.isKept == false }

    interactor.sendAction(.toggleKeep)

    #expect(interactor.store.state.isKept == true)
    #expect(interactor.store.state.isUpdatingKeep)
    await waitUntil { !interactor.store.state.isUpdatingKeep }
    #expect(await repository.keptEpisodeIDs == Set([episode.id]))
  }

  @MainActor
  @Test
  func toggleKeptEpisodeUpdatesOptimisticallyAndUnkeeps() async {
    let repository = KeepRepositorySpy(isKept: true)
    let episode = makeEpisode()
    let interactor = EpisodeInteractor(
      episode: episode,
      dependency: Dependency(keepRepository: repository)
    )
    interactor.activate()
    await waitUntil { interactor.store.state.isKept == true }

    interactor.sendAction(.toggleKeep)

    #expect(interactor.store.state.isKept == false)
    #expect(interactor.store.state.isUpdatingKeep)
    await waitUntil { !interactor.store.state.isUpdatingKeep }
    #expect(await repository.isKept(episodeID: episode.id) == false)
  }

  @MainActor
  @Test
  func failedKeepRestoresPreviousState() async {
    let repository = KeepRepositorySpy(isKept: false, shouldFailKeep: true)
    let interactor = EpisodeInteractor(
      episode: makeEpisode(),
      dependency: Dependency(keepRepository: repository)
    )
    interactor.activate()
    await waitUntil { interactor.store.state.isKept == false }

    interactor.sendAction(.toggleKeep)
    await waitUntil { interactor.store.state.keepErrorMessage != nil }

    #expect(interactor.store.state.isKept == false)
    #expect(!interactor.store.state.isUpdatingKeep)
  }
}

private func makeEpisode() -> Entity.Episode {
  Entity.Episode(
    id: EpisodeID("episode-guid"),
    podcastID: PodcastID(42),
    podcastTitle: "Architecture Talks",
    title: "View-controller-centered RIBs",
    feedURL: URL(string: "https://example.com/feed.xml")!,
    audioURL: URL(string: "https://example.com/audio.mp3")
  )
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async {
  for _ in 0 ..< 100 {
    if condition() { return }
    await Task.yield()
  }
}

private struct Dependency: EpisodeDependency {
  let keepRepository: KeepRepository

  init(keepRepository: KeepRepository = KeepRepositorySpy()) {
    self.keepRepository = keepRepository
  }
}

private actor KeepRepositorySpy: KeepRepository {
  private var isKeptValue: Bool
  private let shouldFailKeep: Bool
  private(set) var keptEpisodeIDs: Set<EpisodeID> = []

  init(isKept: Bool = false, shouldFailKeep: Bool = false) {
    self.isKeptValue = isKept
    self.shouldFailKeep = shouldFailKeep
  }

  func fetchKeptEpisodes() -> [KeptEpisode] { [] }

  func isKept(episodeID: EpisodeID) -> Bool {
    isKeptValue
  }

  func keep(_ episode: Entity.Episode) throws {
    if shouldFailKeep { throw KeepRepositorySpyError.failed }
    isKeptValue = true
    keptEpisodeIDs.insert(episode.id)
  }

  func unkeep(episodeID: EpisodeID) {
    isKeptValue = false
    keptEpisodeIDs.remove(episodeID)
  }
}

private enum KeepRepositorySpyError: Error {
  case failed
}

@MainActor
private final class Listener: EpisodeListener {}
