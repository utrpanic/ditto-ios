import Foundation
import Playback
import RIBsLite

enum PlayerAction {
  case togglePlayback
  case seek(to: TimeInterval)
  case skipBackward
  case skipForward
  case presentExpanded
  case dismissExpanded
}

@MainActor
protocol PlayerInteractable: AnyObject {
  var store: StateStore<PlayerState> { get }
  func sendAction(_ action: PlayerAction)
}

@MainActor
final class PlayerInteractor: Interactor, PlayerInteractable {
  private let playbackController: PlaybackControlling

  let store = StateStore(PlayerState())
  var router: PlayerRouting?
  weak var listener: PlayerListener?

  private var playbackObservationTask: Task<Void, Never>?
  private var seekTask: Task<Void, Never>?

  init(dependency: PlayerDependency) {
    self.playbackController = dependency.playbackController
  }

  deinit {
    playbackObservationTask?.cancel()
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
}
