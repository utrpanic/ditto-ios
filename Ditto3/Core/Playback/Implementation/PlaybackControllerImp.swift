import Entity
import Foundation
import Platform
import Playback

@MainActor
public final class PlaybackControllerImp: PlaybackControlling {
  public static let backwardInterval: TimeInterval = 15
  public static let forwardInterval: TimeInterval = 30

  private let player: AVPlayerProtocol
  private let audioSession: AVAudioSessionProtocol
  private let remoteCommandCenter: MPRemoteCommandCenterProtocol
  private let nowPlayingInfoCenter: MPNowPlayingInfoCenterProtocol
  private let now: () -> Date

  private var state: PlaybackState = .idle
  private var changeContinuations: [UUID: AsyncStream<PlaybackState>.Continuation] = [:]
  private var completionContinuations: [UUID: AsyncStream<PlaybackSession>.Continuation] = [:]
  private var timeObserver: Any?
  private var playbackEndObserver: Any?
  private var resetRemoteCommands: (() -> Void)?
  private var restoredSessionNeedsPreparation = false

  public init(
    player: AVPlayerProtocol,
    audioSession: AVAudioSessionProtocol,
    remoteCommandCenter: MPRemoteCommandCenterProtocol,
    nowPlayingInfoCenter: MPNowPlayingInfoCenterProtocol
  ) {
    self.player = player
    self.audioSession = audioSession
    self.remoteCommandCenter = remoteCommandCenter
    self.nowPlayingInfoCenter = nowPlayingInfoCenter
    self.now = { Date() }
    configureSystemObservers()
  }

  init(
    player: AVPlayerProtocol,
    audioSession: AVAudioSessionProtocol,
    remoteCommandCenter: MPRemoteCommandCenterProtocol,
    nowPlayingInfoCenter: MPNowPlayingInfoCenterProtocol,
    now: @escaping () -> Date
  ) {
    self.player = player
    self.audioSession = audioSession
    self.remoteCommandCenter = remoteCommandCenter
    self.nowPlayingInfoCenter = nowPlayingInfoCenter
    self.now = now
    configureSystemObservers()
  }

  deinit {
    let player = player
    let timeObserver = timeObserver
    let playbackEndObserver = playbackEndObserver
    let resetRemoteCommands = resetRemoteCommands
    Task { @MainActor in
      if let timeObserver {
        player.removeTimeObserver(timeObserver)
      }
      if let playbackEndObserver {
        player.removePlaybackEndObserver(playbackEndObserver)
      }
      resetRemoteCommands?()
    }
  }

  public func play(_ episode: Episode) async {
    restoredSessionNeedsPreparation = false
    let session = PlaybackSession(episode: episode, position: 0, updatedAt: now())
    guard let audioURL = episode.audioURL else {
      publish(.failed(session, message: "This episode has no playable audio URL."))
      return
    }

    publish(.loading(session))
    do {
      try audioSession.activatePlayback()
      player.load(url: audioURL)
      player.play()
      publish(.playing(session))
    } catch {
      publish(.failed(session, message: error.localizedDescription))
    }
  }

  public func restore(_ session: PlaybackSession) async {
    let position = clamped(session.position, duration: session.episode.duration)
    restoredSessionNeedsPreparation = true
    publish(.paused(PlaybackSession(
      episode: session.episode,
      position: position,
      updatedAt: session.updatedAt
    )))
  }

  public func play() async {
    let session: PlaybackSession
    switch state {
    case .paused(let currentSession), .playing(let currentSession):
      session = currentSession
    case .idle, .loading, .failed:
      return
    }
    do {
      try audioSession.activatePlayback()
      if restoredSessionNeedsPreparation {
        guard let audioURL = session.episode.audioURL else {
          publish(.failed(session, message: "This episode has no playable audio URL."))
          return
        }
        player.load(url: audioURL)
        await player.seek(to: session.position)
        restoredSessionNeedsPreparation = false
      }
      player.play()
      publish(.playing(updatedSession(session, position: player.playbackCurrentTime)))
    } catch {
      publish(.failed(session, message: error.localizedDescription))
    }
  }

  public func pause() {
    guard case .playing(let session) = state else { return }
    player.pause()
    publish(.paused(updatedSession(session, position: player.playbackCurrentTime)))
  }

  public func seek(to position: TimeInterval) async {
    let session: PlaybackSession
    switch state {
    case .loading(let currentSession), .paused(let currentSession), .playing(let currentSession):
      session = currentSession
    case .idle, .failed:
      return
    }
    let position = clamped(position, duration: session.episode.duration)
    if !restoredSessionNeedsPreparation {
      await player.seek(to: position)
    }
    let updatedSession = updatedSession(session, position: position)

    switch state {
    case .playing:
      publish(.playing(updatedSession))
    case .loading:
      publish(.loading(updatedSession))
    case .paused:
      publish(.paused(updatedSession))
    case .idle, .failed:
      break
    }
  }

  public func skipBackward() {
    let position = restoredSessionNeedsPreparation
      ? currentSession?.position ?? 0
      : player.playbackCurrentTime
    let target = position - Self.backwardInterval
    Task { @MainActor [weak self] in
      await self?.seek(to: target)
    }
  }

  public func skipForward() {
    let position = restoredSessionNeedsPreparation
      ? currentSession?.position ?? 0
      : player.playbackCurrentTime
    let target = position + Self.forwardInterval
    Task { @MainActor [weak self] in
      await self?.seek(to: target)
    }
  }

  public func stateChanges() -> AsyncStream<PlaybackState> {
    let id = UUID()
    let (stream, continuation) = AsyncStream<PlaybackState>.makeStream()
    continuation.yield(state)
    continuation.onTermination = { [weak self] _ in
      Task { @MainActor in
        self?.changeContinuations[id] = nil
      }
    }
    changeContinuations[id] = continuation
    return stream
  }

  public func completionEvents() -> AsyncStream<PlaybackSession> {
    let id = UUID()
    let (stream, continuation) = AsyncStream<PlaybackSession>.makeStream()
    continuation.onTermination = { [weak self] _ in
      Task { @MainActor in
        self?.completionContinuations[id] = nil
      }
    }
    completionContinuations[id] = continuation
    return stream
  }

  private func configureSystemObservers() {
    timeObserver = player.addPeriodicTimeObserver { [weak self] position in
      self?.updatePosition(position)
    }
    playbackEndObserver = player.observePlaybackEnd { [weak self] in
      self?.handlePlaybackEnd()
    }
    resetRemoteCommands = remoteCommandCenter.configurePlaybackCommands(
      backwardInterval: Self.backwardInterval,
      forwardInterval: Self.forwardInterval,
      play: { [weak self] in
        Task { @MainActor in
          await self?.play()
        }
      },
      pause: { [weak self] in self?.pause() },
      seek: { [weak self] position in
        Task { @MainActor in
          await self?.seek(to: position)
        }
      },
      skipBackward: { [weak self] in self?.skipBackward() },
      skipForward: { [weak self] in self?.skipForward() }
    )
  }

  private func handlePlaybackEnd() {
    guard let session = currentSession else { return }
    restoredSessionNeedsPreparation = false
    let completedSession = updatedSession(session, position: player.playbackCurrentTime)
    publish(.idle)
    for continuation in completionContinuations.values {
      continuation.yield(completedSession)
    }
  }

  private var currentSession: PlaybackSession? {
    switch state {
    case .idle:
      nil
    case .loading(let session), .paused(let session), .playing(let session):
      session
    case .failed(let session, _):
      session
    }
  }

  private func updatePosition(_ position: TimeInterval) {
    guard let session = currentSession else { return }
    let updatedSession = updatedSession(
      session,
      position: clamped(position, duration: session.episode.duration)
    )

    switch state {
    case .playing:
      publish(.playing(updatedSession))
    case .paused:
      publish(.paused(updatedSession))
    case .idle, .loading, .failed:
      break
    }
  }

  private func publish(_ state: PlaybackState) {
    self.state = state
    updateNowPlayingInfo(for: state)
    for continuation in changeContinuations.values {
      continuation.yield(state)
    }
  }

  private func updateNowPlayingInfo(for state: PlaybackState) {
    guard let session = state.session else {
      nowPlayingInfoCenter.update(
        title: nil,
        podcastTitle: nil,
        duration: nil,
        position: nil,
        isPlaying: false
      )
      return
    }

    nowPlayingInfoCenter.update(
      title: session.episode.title,
      podcastTitle: session.episode.podcastTitle,
      duration: session.episode.duration,
      position: session.position,
      isPlaying: state.isPlaying
    )
  }

  private func updatedSession(
    _ session: PlaybackSession,
    position: TimeInterval
  ) -> PlaybackSession {
    PlaybackSession(
      episode: session.episode,
      position: position,
      updatedAt: now()
    )
  }

  private func clamped(_ position: TimeInterval, duration: TimeInterval?) -> TimeInterval {
    let position = max(position, 0)
    guard let duration, duration.isFinite, duration > 0 else { return position }
    return min(position, duration)
  }
}

private extension PlaybackState {
  var session: PlaybackSession? {
    switch self {
    case .idle:
      nil
    case .loading(let session), .paused(let session), .playing(let session):
      session
    case .failed(let session, _):
      session
    }
  }

  var isPlaying: Bool {
    if case .playing = self { return true }
    return false
  }
}
