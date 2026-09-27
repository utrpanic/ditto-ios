import Entity
import Foundation
import Playback
import Repository
import RIBsLite

enum PlayerAction {
  case viewDidLoad
  case togglePlayback
  case seek(to: TimeInterval)
  case skipBackward
  case skipForward
  case presentExpanded
  case dismissExpanded
  case playQueueItem(EpisodeID)
  case viewQueueEpisode(EpisodeID)
  case moveQueueItem(EpisodeID, to: Int)
  case removeQueueItem(EpisodeID)
  case clearQueue
}

@MainActor
protocol PlayerInteractable: AnyObject {
  var store: StateStore<PlayerState> { get }
  func sendAction(_ action: PlayerAction)
}

@MainActor
final class PlayerInteractor: Interactor, PlayerInteractable {
  private static let persistenceInterval: TimeInterval = 5

  private let playbackController: PlaybackControlling
  private let playbackQueueRepository: PlaybackQueueRepository
  private let playbackSessionRepository: PlaybackSessionRepository

  let store = StateStore(PlayerState())
  var router: PlayerRouting?
  weak var listener: PlayerListener?

  private var playbackObservationTask: Task<Void, Never>?
  private var completionObservationTask: Task<Void, Never>?
  private var queueObservationTask: Task<Void, Never>?
  private var queueMutationTask: Task<Void, Never>?
  private var seekTask: Task<Void, Never>?
  private var playbackControlTask: Task<Void, Never>?
  private var lastPersistedSession: PlaybackSession?

  init(dependency: PlayerDependency) {
    self.playbackController = dependency.playbackController
    self.playbackQueueRepository = dependency.playbackQueueRepository
    self.playbackSessionRepository = dependency.playbackSessionRepository
  }

  deinit {
    playbackObservationTask?.cancel()
    completionObservationTask?.cancel()
    queueObservationTask?.cancel()
  }

  func sendAction(_ action: PlayerAction) {
    switch action {
    case .viewDidLoad:
      listener?.playerVisibilityDidChange(store.state.session != nil)
      playbackObservationTask?.cancel()
      let playbackController = playbackController
      let playbackSessionRepository = playbackSessionRepository
      playbackObservationTask = Task { [weak self, weak store] in
        if let session = try? await playbackSessionRepository.loadSession() {
          await playbackController.restore(session)
        }
        let changes = playbackController.stateChanges()
        for await playback in changes {
          guard !Task.isCancelled, let self, let store else { return }
          let wasVisible = store.state.session != nil
          store.state.playback = playback
          if store.state.session == nil {
            store.state.isExpanded = false
          }
          let isVisible = store.state.session != nil
          if isVisible != wasVisible {
            listener?.playerVisibilityDidChange(isVisible)
          }
          await persist(playback)
        }
      }

      observePlaybackCompletion()
      observeQueue()
    case .togglePlayback:
      togglePlayback()
    case .seek(let position):
      seek(to: position)
    case .skipBackward:
      playbackController.skipBackward()
    case .skipForward:
      playbackController.skipForward()
    case .presentExpanded:
      guard store.state.session != nil else { return }
      store.state.isExpanded = true
    case .dismissExpanded:
      store.state.isExpanded = false
    case .playQueueItem(let episodeID):
      playQueueItem(episodeID)
    case .viewQueueEpisode(let episodeID):
      guard let episode = store.state.queue.first(where: { $0.episode.id == episodeID })?.episode else { return }
      store.state.isExpanded = false
      listener?.playerDidRequestEpisode(episode)
    case .moveQueueItem(let episodeID, let index):
      mutateQueue { repository in
        try await repository.move(episodeID: episodeID, to: index)
      }
    case .removeQueueItem(let episodeID):
      mutateQueue { repository in
        try await repository.remove(episodeID: episodeID)
      }
    case .clearQueue:
      mutateQueue { repository in
        try await repository.removeAll()
      }
    }
  }

  private func togglePlayback() {
    switch store.state.playback {
    case .playing:
      playbackController.pause()
    case .paused:
      playbackControlTask?.cancel()
      let playbackController = playbackController
      playbackControlTask = Task {
        await playbackController.play()
      }
    case .idle, .loading, .failed:
      break
    }
  }

  private func persist(_ playback: PlaybackState) async {
    do {
      switch playback {
      case .idle:
        try await playbackSessionRepository.clearSession()
        lastPersistedSession = nil
      case .loading(let session), .paused(let session):
        try await save(session)
      case .playing(let session):
        guard shouldPersistProgress(session) else { return }
        try await save(session)
      case .failed(let session, _):
        if let session {
          try await save(session)
        } else {
          try await playbackSessionRepository.clearSession()
          lastPersistedSession = nil
        }
      }
    } catch {
      return
    }
  }

  private func shouldPersistProgress(_ session: PlaybackSession) -> Bool {
    guard let lastPersistedSession else { return true }
    guard lastPersistedSession.episode.id == session.episode.id else { return true }
    return abs(session.position - lastPersistedSession.position) >= Self.persistenceInterval
  }

  private func save(_ session: PlaybackSession) async throws {
    try await playbackSessionRepository.saveSession(session)
    lastPersistedSession = session
  }

  private func seek(to position: TimeInterval) {
    seekTask?.cancel()
    let playbackController = playbackController
    seekTask = Task {
      await playbackController.seek(to: position)
    }
  }

  private func observeQueue() {
    queueObservationTask?.cancel()
    let playbackQueueRepository = playbackQueueRepository
    queueObservationTask = Task { [weak store] in
      let changes = await playbackQueueRepository.changes()
      await Self.reloadQueue(from: playbackQueueRepository, into: store)
      for await _ in changes {
        guard !Task.isCancelled else { return }
        await Self.reloadQueue(from: playbackQueueRepository, into: store)
      }
    }
  }

  private func observePlaybackCompletion() {
    completionObservationTask?.cancel()
    let playbackController = playbackController
    let playbackQueueRepository = playbackQueueRepository
    completionObservationTask = Task { [weak store] in
      let completions = playbackController.completionEvents()
      for await _ in completions {
        guard !Task.isCancelled else { return }
        do {
          guard let item = try await playbackQueueRepository.dequeue() else { continue }
          await playbackController.play(item.episode)
          store?.state.queueFailureMessage = nil
        } catch {
          store?.state.queueFailureMessage = error.localizedDescription
        }
      }
    }
  }

  private func playQueueItem(_ episodeID: EpisodeID) {
    guard let item = store.state.queue.first(where: { $0.episode.id == episodeID }) else { return }
    let playbackController = playbackController
    mutateQueue { repository in
      try await repository.remove(episodeID: episodeID)
      await playbackController.play(item.episode)
    }
  }

  private func mutateQueue(
    _ mutation: @escaping (PlaybackQueueRepository) async throws -> Void
  ) {
    queueMutationTask?.cancel()
    let playbackQueueRepository = playbackQueueRepository
    queueMutationTask = Task { [weak store] in
      do {
        try await mutation(playbackQueueRepository)
        store?.state.queueFailureMessage = nil
      } catch {
        store?.state.queueFailureMessage = error.localizedDescription
        await Self.reloadQueue(from: playbackQueueRepository, into: store)
      }
    }
  }

  private static func reloadQueue(
    from repository: PlaybackQueueRepository,
    into store: StateStore<PlayerState>?
  ) async {
    do {
      store?.state.queue = try await repository.fetchQueue()
      store?.state.queueFailureMessage = nil
    } catch {
      store?.state.queueFailureMessage = error.localizedDescription
    }
  }
}
