import Entity
import Foundation
import Playback
import Repository
import RIBsLite

enum PlayerAction {
  case togglePlayback
  case seek(to: TimeInterval)
  case skipBackward
  case skipForward
  case presentExpanded
  case dismissExpanded
  case playQueueItem(EpisodeID)
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
  private let playbackController: PlaybackControlling
  private let playbackQueueRepository: PlaybackQueueRepository

  let store = StateStore(PlayerState())
  var router: PlayerRouting?
  weak var listener: PlayerListener?

  private var playbackObservationTask: Task<Void, Never>?
  private var queueObservationTask: Task<Void, Never>?
  private var queueMutationTask: Task<Void, Never>?
  private var seekTask: Task<Void, Never>?

  init(dependency: PlayerDependency) {
    self.playbackController = dependency.playbackController
    self.playbackQueueRepository = dependency.playbackQueueRepository
  }

  deinit {
    playbackObservationTask?.cancel()
    queueObservationTask?.cancel()
    queueMutationTask?.cancel()
    seekTask?.cancel()
  }

  override func didBecomeActive() {
    playbackObservationTask?.cancel()
    let playbackController = playbackController
    playbackObservationTask = Task { [weak store] in
      let changes = playbackController.stateChanges()
      for await playback in changes {
        guard !Task.isCancelled, let store else { return }
        store.state.playback = playback
        if store.state.session == nil {
          store.state.isExpanded = false
        }
      }
    }

    observeQueue()
  }

  func sendAction(_ action: PlayerAction) {
    switch action {
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
      playbackController.play()
    case .idle, .loading, .failed:
      break
    }
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
