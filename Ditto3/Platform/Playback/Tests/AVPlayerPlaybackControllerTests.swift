import Entity
import Foundation
import Playback
@testable import PlaybackImp
import Testing

struct AVPlayerPlaybackControllerTests {
  @MainActor
  @Test
  func playPauseAndResumePublishStateTransitions() async {
    let player = AudioPlayerSpy()
    let now = Date(timeIntervalSince1970: 1_000)
    let controller = makeController(player: player, now: now)
    var states = controller.stateChanges().makeAsyncIterator()
    #expect(await states.next() == .idle)

    let episode = makeEpisode()
    await controller.play(episode)

    #expect(await states.next() == .loading(makeSession(episode: episode, position: 0, now: now)))
    #expect(await states.next() == .playing(makeSession(episode: episode, position: 0, now: now)))
    #expect(player.loadedURL == episode.audioURL)
    #expect(player.playCallCount == 1)

    player.currentTime = 42
    controller.pause()
    #expect(await states.next() == .paused(makeSession(episode: episode, position: 42, now: now)))
    #expect(player.pauseCallCount == 1)

    controller.play()
    #expect(await states.next() == .playing(makeSession(episode: episode, position: 42, now: now)))
    #expect(player.playCallCount == 2)
  }

  @MainActor
  @Test
  func seekAndSkipClampToEpisodeBounds() async {
    let player = AudioPlayerSpy()
    let controller = makeController(player: player)
    await controller.play(makeEpisode(duration: 120))

    await controller.seek(to: -10)
    #expect(player.seekPositions.last == 0)

    await controller.seek(to: 500)
    #expect(player.seekPositions.last == 120)

    player.currentTime = 50
    controller.skipBackward()
    await waitUntil { player.seekPositions.last == 35 }

    player.currentTime = 50
    controller.skipForward()
    await waitUntil { player.seekPositions.last == 80 }
  }

  @MainActor
  @Test
  func periodicTimeUpdatesCurrentPlayingSession() async {
    let player = AudioPlayerSpy()
    let nowPlayingInfo = NowPlayingInfoSpy()
    let controller = makeController(player: player, nowPlayingInfo: nowPlayingInfo)
    var states = controller.stateChanges().makeAsyncIterator()
    _ = await states.next()
    await controller.play(makeEpisode())
    _ = await states.next()
    _ = await states.next()

    player.emitTime(18)

    guard case .playing(let session)? = await states.next() else {
      Issue.record("Expected a playing state with updated progress.")
      return
    }
    #expect(session.position == 18)
    #expect(nowPlayingInfo.states.last == .playing(session))
  }

  @MainActor
  @Test
  func missingAudioURLPublishesFailure() async {
    let controller = makeController()
    var states = controller.stateChanges().makeAsyncIterator()
    _ = await states.next()
    let episode = makeEpisode(audioURL: nil)

    await controller.play(episode)

    guard case .failed(let session, _)? = await states.next() else {
      Issue.record("Expected a failed playback state.")
      return
    }
    #expect(session?.episode == episode)
  }

  @MainActor
  @Test
  func audioSessionFailurePreservesEpisodeInFailureState() async {
    let controller = makeController(audioSession: AudioSessionSpy(shouldFail: true))
    var states = controller.stateChanges().makeAsyncIterator()
    _ = await states.next()
    let episode = makeEpisode()

    await controller.play(episode)
    _ = await states.next()

    guard case .failed(let session, _)? = await states.next() else {
      Issue.record("Expected a failed playback state.")
      return
    }
    #expect(session?.episode == episode)
  }

  @MainActor
  @Test
  func remoteCommandsControlPlayback() async {
    let player = AudioPlayerSpy()
    let remoteCommands = RemoteCommandSpy()
    let controller = makeController(player: player, remoteCommands: remoteCommands)
    await controller.play(makeEpisode())

    remoteCommands.pause?()
    #expect(player.pauseCallCount == 1)

    remoteCommands.play?()
    #expect(player.playCallCount == 2)

    remoteCommands.seek?(64)
    await waitUntil { player.seekPositions.last == 64 }
  }
}

@MainActor
private func makeController(
  player: AudioPlayerSpy? = nil,
  audioSession: AudioSessionSpy? = nil,
  remoteCommands: RemoteCommandSpy? = nil,
  nowPlayingInfo: NowPlayingInfoSpy? = nil,
  now: Date = Date(timeIntervalSince1970: 1_000)
) -> AVPlayerPlaybackController {
  AVPlayerPlaybackController(
    player: player ?? AudioPlayerSpy(),
    audioSession: audioSession ?? AudioSessionSpy(),
    remoteCommands: remoteCommands ?? RemoteCommandSpy(),
    nowPlayingInfo: nowPlayingInfo ?? NowPlayingInfoSpy(),
    now: { now }
  )
}

private func makeEpisode(
  audioURL: URL? = URL(string: "https://example.com/episode.mp3"),
  duration: TimeInterval = 120
) -> Episode {
  Episode(
    id: EpisodeID("episode-id"),
    podcastTitle: "Architecture Talks",
    title: "Playback Foundation",
    feedURL: URL(string: "https://example.com/feed.xml")!,
    audioURL: audioURL,
    duration: duration
  )
}

private func makeSession(
  episode: Episode,
  position: TimeInterval,
  now: Date
) -> PlaybackSession {
  PlaybackSession(episode: episode, position: position, updatedAt: now)
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async {
  for _ in 0..<1_000 {
    guard !condition() else { return }
    await Task.yield()
  }
}

@MainActor
private final class AudioPlayerSpy: AudioPlayerControlling {
  var currentTime: TimeInterval = 0
  private(set) var loadedURL: URL?
  private(set) var playCallCount = 0
  private(set) var pauseCallCount = 0
  private(set) var seekPositions: [TimeInterval] = []
  private var timeHandler: ((TimeInterval) -> Void)?

  func load(url: URL) {
    loadedURL = url
    currentTime = 0
  }

  func play() {
    playCallCount += 1
  }

  func pause() {
    pauseCallCount += 1
  }

  func seek(to position: TimeInterval) async {
    seekPositions.append(position)
    currentTime = position
  }

  func addPeriodicTimeObserver(_ handler: @escaping (TimeInterval) -> Void) -> Any {
    timeHandler = handler
    return NSObject()
  }

  func removeTimeObserver(_ observer: Any) {
    timeHandler = nil
  }

  func emitTime(_ position: TimeInterval) {
    currentTime = position
    timeHandler?(position)
  }
}

@MainActor
private final class AudioSessionSpy: AudioSessionControlling {
  private let shouldFail: Bool

  init(shouldFail: Bool = false) {
    self.shouldFail = shouldFail
  }

  func activatePlayback() throws {
    if shouldFail { throw AudioSessionError.failed }
  }
}

private enum AudioSessionError: LocalizedError {
  case failed

  var errorDescription: String? { "Audio session activation failed." }
}

@MainActor
private final class RemoteCommandSpy: RemoteCommandConfiguring {
  private(set) var play: (() -> Void)?
  private(set) var pause: (() -> Void)?
  private(set) var seek: ((TimeInterval) -> Void)?
  private(set) var skipBackward: (() -> Void)?
  private(set) var skipForward: (() -> Void)?

  func configure(
    play: @escaping () -> Void,
    pause: @escaping () -> Void,
    seek: @escaping (TimeInterval) -> Void,
    skipBackward: @escaping () -> Void,
    skipForward: @escaping () -> Void
  ) {
    self.play = play
    self.pause = pause
    self.seek = seek
    self.skipBackward = skipBackward
    self.skipForward = skipForward
  }

  func reset() {
    play = nil
    pause = nil
    seek = nil
    skipBackward = nil
    skipForward = nil
  }
}

@MainActor
private final class NowPlayingInfoSpy: NowPlayingInfoUpdating {
  private(set) var states: [PlaybackState] = []

  func update(_ state: PlaybackState) {
    states.append(state)
  }
}
