import Entity
import Foundation
import Playback

@MainActor
public final class AVPlayerPlaybackController: PlaybackControlling {
  public static let backwardInterval: TimeInterval = 15
  public static let forwardInterval: TimeInterval = 30

  private let player: AudioPlayerControlling
  private let audioSession: AudioSessionControlling
  private let remoteCommands: RemoteCommandConfiguring
  private let nowPlayingInfo: NowPlayingInfoUpdating
  private let now: () -> Date

  private var state: PlaybackState = .idle
  private var changeContinuations: [UUID: AsyncStream<PlaybackState>.Continuation] = [:]
  private var timeObserver: Any?

  public convenience init() {
    self.init(
      player: AVPlayerAdapter(),
      audioSession: AVAudioSessionAdapter(),
      remoteCommands: SystemRemoteCommandCenter(),
      nowPlayingInfo: SystemNowPlayingInfoCenter(),
      now: { Date() }
    )
  }

  init(
    player: AudioPlayerControlling,
    audioSession: AudioSessionControlling,
    remoteCommands: RemoteCommandConfiguring,
    nowPlayingInfo: NowPlayingInfoUpdating,
    now: @escaping () -> Date
  ) {
    self.player = player
    self.audioSession = audioSession
    self.remoteCommands = remoteCommands
    self.nowPlayingInfo = nowPlayingInfo
    self.now = now

    timeObserver = player.addPeriodicTimeObserver { [weak self] position in
      self?.updatePosition(position)
    }
    remoteCommands.configure(
      play: { [weak self] in self?.play() },
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

  deinit {
    let player = player
    let remoteCommands = remoteCommands
    let timeObserver = timeObserver
    Task { @MainActor in
      if let timeObserver {
        player.removeTimeObserver(timeObserver)
      }
      remoteCommands.reset()
    }
  }

  public func play(_ episode: Episode) async {
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

  public func play() {
    let session: PlaybackSession
    switch state {
    case .paused(let currentSession), .playing(let currentSession):
      session = currentSession
    case .idle, .loading, .failed:
      return
    }
    player.play()
    publish(.playing(updatedSession(session, position: player.currentTime)))
  }

  public func pause() {
    guard case .playing(let session) = state else { return }
    player.pause()
    publish(.paused(updatedSession(session, position: player.currentTime)))
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
    await player.seek(to: position)
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
    let target = player.currentTime - Self.backwardInterval
    Task { @MainActor [weak self] in
      await self?.seek(to: target)
    }
  }

  public func skipForward() {
    let target = player.currentTime + Self.forwardInterval
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
    nowPlayingInfo.update(state)
    for continuation in changeContinuations.values {
      continuation.yield(state)
    }
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
