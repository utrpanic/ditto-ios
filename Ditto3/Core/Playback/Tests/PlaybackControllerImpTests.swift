import Entity
import Foundation
import PlatformTestSupport
import Playback
import Testing
@testable import PlaybackImp

struct PlaybackControllerImpTests {
  @MainActor
  @Test
  func playPauseAndResumePublishStateTransitions() async {
    let player = AVPlayerMock()
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

    player.playbackCurrentTime = 42
    controller.pause()
    #expect(await states.next() == .paused(makeSession(episode: episode, position: 42, now: now)))
    #expect(player.pauseCallCount == 1)

    await controller.play()
    #expect(await states.next() == .playing(makeSession(episode: episode, position: 42, now: now)))
    #expect(player.playCallCount == 2)
  }

  @MainActor
  @Test
  func restoreDefersLoadingAndSeekingUntilPlaybackStarts() async {
    let player = AVPlayerMock()
    let audioSession = AVAudioSessionMock()
    let controller = makeController(player: player, audioSession: audioSession)
    var states = controller.stateChanges().makeAsyncIterator()
    _ = await states.next()
    let episode = makeEpisode(duration: 120)
    let session = makeSession(
      episode: episode,
      position: 42,
      now: Date(timeIntervalSince1970: 500)
    )

    await controller.restore(session)

    #expect(await states.next() == .paused(session))
    #expect(player.loadedURL == nil)
    #expect(player.seekPositions.isEmpty)
    #expect(player.playCallCount == 0)
    #expect(audioSession.activationCallCount == 0)

    await controller.play()

    #expect(player.loadedURL == episode.audioURL)
    #expect(player.seekPositions == [42])
    #expect(player.playCallCount == 1)
    #expect(audioSession.activationCallCount == 1)
  }

  @MainActor
  @Test
  func seekAndSkipClampToEpisodeBounds() async {
    let player = AVPlayerMock()
    let controller = makeController(player: player)
    await controller.play(makeEpisode(duration: 120))

    await controller.seek(to: -10)
    #expect(player.seekPositions.last == 0)

    await controller.seek(to: 500)
    #expect(player.seekPositions.last == 120)

    player.playbackCurrentTime = 50
    controller.skipBackward()
    await waitUntil { player.seekPositions.last == 35 }

    player.playbackCurrentTime = 50
    controller.skipForward()
    await waitUntil { player.seekPositions.last == 80 }
  }

  @MainActor
  @Test
  func periodicTimeUpdatesStateAndNowPlayingInfo() async {
    let player = AVPlayerMock()
    let nowPlayingInfoCenter = MPNowPlayingInfoCenterMock()
    let controller = makeController(
      player: player,
      nowPlayingInfoCenter: nowPlayingInfoCenter
    )
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
    #expect(nowPlayingInfoCenter.updates.last?.position == 18)
    #expect(nowPlayingInfoCenter.updates.last?.isPlaying == true)
  }

  @MainActor
  @Test
  func playbackEndPublishesCompletedSessionAndReturnsToIdle() async {
    let player = AVPlayerMock()
    let now = Date(timeIntervalSince1970: 1_000)
    let controller = makeController(player: player, now: now)
    var states = controller.stateChanges().makeAsyncIterator()
    var completions = controller.completionEvents().makeAsyncIterator()
    _ = await states.next()
    let episode = makeEpisode()
    await controller.play(episode)
    _ = await states.next()
    _ = await states.next()
    player.playbackCurrentTime = 120

    player.emitPlaybackEnd()

    #expect(await states.next() == .idle)
    #expect(await completions.next() == makeSession(episode: episode, position: 120, now: now))
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
    let audioSession = AVAudioSessionMock()
    audioSession.shouldFail = true
    let controller = makeController(audioSession: audioSession)
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
    let player = AVPlayerMock()
    let remoteCommandCenter = MPRemoteCommandCenterMock()
    let controller = makeController(
      player: player,
      remoteCommandCenter: remoteCommandCenter
    )
    await controller.play(makeEpisode())

    remoteCommandCenter.sendPause()
    #expect(player.pauseCallCount == 1)

    remoteCommandCenter.sendPlay()
    await waitUntil { player.playCallCount == 2 }
    #expect(player.playCallCount == 2)

    remoteCommandCenter.sendSeek(to: 64)
    await waitUntil { player.seekPositions.last == 64 }
    #expect(remoteCommandCenter.backwardInterval == PlaybackControllerImp.backwardInterval)
    #expect(remoteCommandCenter.forwardInterval == PlaybackControllerImp.forwardInterval)
  }
}

@MainActor
private func makeController(
  player: AVPlayerMock? = nil,
  audioSession: AVAudioSessionMock? = nil,
  remoteCommandCenter: MPRemoteCommandCenterMock? = nil,
  nowPlayingInfoCenter: MPNowPlayingInfoCenterMock? = nil,
  now: Date = Date(timeIntervalSince1970: 1_000)
) -> PlaybackControllerImp {
  PlaybackControllerImp(
    player: player ?? AVPlayerMock(),
    audioSession: audioSession ?? AVAudioSessionMock(),
    remoteCommandCenter: remoteCommandCenter ?? MPRemoteCommandCenterMock(),
    nowPlayingInfoCenter: nowPlayingInfoCenter ?? MPNowPlayingInfoCenterMock(),
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
