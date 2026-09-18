import Entity
import Playback
import Repository
import RIBsLite

@MainActor
protocol EpisodeInteractable: AnyObject {
  var store: StateStore<EpisodeState> { get }
  func sendAction(_ action: EpisodeAction)
}

@MainActor
final class EpisodeInteractor: Interactor, EpisodeInteractable {
  let store: StateStore<EpisodeState>
  var router: EpisodeRouting?
  weak var listener: EpisodeListener?
  private let playbackController: PlaybackControlling
  private let playbackQueueRepository: PlaybackQueueRepository

  init(episode: Episode, dependency: EpisodeDependency) {
    self.store = StateStore(EpisodeState(episode: episode))
    self.playbackController = dependency.playbackController
    self.playbackQueueRepository = dependency.playbackQueueRepository
    super.init()
  }

  func sendAction(_ action: EpisodeAction) {
    switch action {
    case .play:
      let episode = store.state.episode
      let playbackController = playbackController
      Task {
        await playbackController.play(episode)
      }
    case .playNext:
      playNext()
    case .addToQueue:
      addToQueue()
    }
  }

  private func playNext() {
    let episode = store.state.episode
    let playbackController = playbackController
    let playbackQueueRepository = playbackQueueRepository
    Task { [weak store] in
      let changes = playbackController.stateChanges()
      var iterator = changes.makeAsyncIterator()
      guard let playback = await iterator.next() else { return }

      if playback.hasSession {
        do {
          try await playbackQueueRepository.playNext(episode)
          store?.state.queueMessage = "Will play next"
        } catch {
          store?.state.queueMessage = error.localizedDescription
        }
      } else {
        await playbackController.play(episode)
        store?.state.queueMessage = "Playing now"
      }
    }
  }

  private func addToQueue() {
    let episode = store.state.episode
    let playbackQueueRepository = playbackQueueRepository
    Task { [weak store] in
      do {
        try await playbackQueueRepository.addToQueue(episode)
        store?.state.queueMessage = "Added to Queue"
      } catch {
        store?.state.queueMessage = error.localizedDescription
      }
    }
  }
}

private extension PlaybackState {
  var hasSession: Bool {
    switch self {
    case .idle:
      false
    case .loading, .paused, .playing:
      true
    case .failed(let session, _):
      session != nil
    }
  }
}
