import Entity
import Foundation
import Playback
import RIBsLite
@testable import Player
import Testing

struct PlayerTests {
  @MainActor
  @Test
  func builderConnectsPlayerRIB() throws {
    let listener = Listener()
    let builder = PlayerBuilder(dependency: Dependency())

    let result = builder.build(listener: listener)

    let viewController = try #require(result as? PlayerViewController)
    let interactor = try #require(viewController.interactor as? PlayerInteractor)
    #expect(interactor.listener === listener)
    #expect(interactor.router != nil)
  }

  @MainActor
  @Test
  func playbackChangesUpdatePlayerAndRevealMiniPlayer() async {
    let playbackController = PlaybackControllerSpy()
    let interactor = PlayerInteractor(dependency: Dependency(playbackController: playbackController))
    let viewController = PlayerViewController(interactor: interactor)
    viewController.loadViewIfNeeded()
    interactor.activate()
    #expect(viewController.view.isHidden)
    await waitUntil { playbackController.streamCallCount == 1 }

    let playbackState = PlaybackState.playing(makeSession())
    playbackController.emit(playbackState)
    await waitUntil { interactor.store.state.playback == playbackState }

    #expect(interactor.store.state.playback == playbackState)
    #expect(!viewController.view.isHidden)
  }

  @MainActor
  @Test
  func controlsForwardToPersistentPlaybackController() async {
    let playbackController = PlaybackControllerSpy(initialState: .paused(makeSession()))
    let interactor = PlayerInteractor(dependency: Dependency(playbackController: playbackController))
    interactor.activate()
    await waitUntil {
      interactor.store.state.playback == playbackController.initialState
    }

    interactor.sendAction(.togglePlayback)
    interactor.sendAction(.skipBackward)
    interactor.sendAction(.skipForward)
    interactor.sendAction(.seek(to: 48))
    await waitUntil { playbackController.seekPositions == [48] }

    #expect(playbackController.playCallCount == 1)
    #expect(playbackController.skipBackwardCallCount == 1)
    #expect(playbackController.skipForwardCallCount == 1)
    #expect(playbackController.seekPositions == [48])
  }

  @MainActor
  @Test
  func expandedPresentationIsPlayerState() async {
    let playbackController = PlaybackControllerSpy(initialState: .playing(makeSession()))
    let interactor = PlayerInteractor(dependency: Dependency(playbackController: playbackController))
    interactor.activate()
    await waitUntil { interactor.store.state.session != nil }

    interactor.sendAction(.presentExpanded)
    #expect(interactor.store.state.isExpanded)

    interactor.sendAction(.dismissExpanded)
    #expect(!interactor.store.state.isExpanded)

    playbackController.emit(.idle)
    await waitUntil { interactor.store.state.playback == .idle }
    interactor.sendAction(.presentExpanded)
    #expect(!interactor.store.state.isExpanded)
  }
}

private func makeSession() -> PlaybackSession {
  PlaybackSession(
    episode: Episode(
      id: EpisodeID("episode-id"),
      podcastTitle: "Architecture Talks",
      title: "Persistent Player",
      feedURL: URL(string: "https://example.com/feed.xml")!,
      audioURL: URL(string: "https://example.com/audio.mp3"),
      duration: 120
    ),
    position: 30,
    updatedAt: Date(timeIntervalSince1970: 1_000)
  )
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async {
  for _ in 0..<1_000 {
    guard !condition() else { return }
    await Task.yield()
  }
}

@MainActor
private struct Dependency: PlayerDependency {
  let playbackController: PlaybackControlling

  init(playbackController: PlaybackControlling? = nil) {
    self.playbackController = playbackController ?? PlaybackControllerSpy()
  }
}

@MainActor
private final class PlaybackControllerSpy: PlaybackControlling {
  let initialState: PlaybackState
  private var continuations: [AsyncStream<PlaybackState>.Continuation] = []
  private(set) var playCallCount = 0
  private(set) var pauseCallCount = 0
  private(set) var skipBackwardCallCount = 0
  private(set) var skipForwardCallCount = 0
  private(set) var seekPositions: [TimeInterval] = []
  private(set) var streamCallCount = 0

  init(initialState: PlaybackState = .idle) {
    self.initialState = initialState
  }

  func play(_ episode: Episode) async {}

  func play() {
    playCallCount += 1
  }

  func pause() {
    pauseCallCount += 1
  }

  func seek(to position: TimeInterval) async {
    seekPositions.append(position)
  }

  func skipBackward() {
    skipBackwardCallCount += 1
  }

  func skipForward() {
    skipForwardCallCount += 1
  }

  func stateChanges() -> AsyncStream<PlaybackState> {
    streamCallCount += 1
    let (stream, continuation) = AsyncStream<PlaybackState>.makeStream()
    continuation.yield(initialState)
    continuations.append(continuation)
    return stream
  }

  func emit(_ state: PlaybackState) {
    for continuation in continuations {
      continuation.yield(state)
    }
  }
}

@MainActor
private final class Listener: PlayerListener {}
