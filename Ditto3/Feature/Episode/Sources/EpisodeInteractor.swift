import Entity
import Repository
import RIBsLite

enum EpisodeAction {
  case toggleKeep
  case retryKeepState
}

@MainActor
protocol EpisodeInteractable: AnyObject {
  var store: StateStore<EpisodeState> { get }
  func sendAction(_ action: EpisodeAction)
}

@MainActor
final class EpisodeInteractor: Interactor, EpisodeInteractable {
  private let dependency: EpisodeDependency
  let store: StateStore<EpisodeState>
  var router: EpisodeRouting?
  weak var listener: EpisodeListener?

  private var keepTask: Task<Void, Never>?

  init(episode: Episode, dependency: EpisodeDependency) {
    self.dependency = dependency
    self.store = StateStore(EpisodeState(episode: episode))
    super.init()
  }

  override func didBecomeActive() {
    loadKeepState()
  }

  func sendAction(_ action: EpisodeAction) {
    switch action {
    case .toggleKeep:
      toggleKeep()
    case .retryKeepState:
      loadKeepState()
    }
  }

  private func loadKeepState() {
    keepTask?.cancel()
    var state = store.state
    state.isKept = nil
    state.isUpdatingKeep = false
    state.keepErrorMessage = nil
    store.state = state

    keepTask = Task { [dependency, weak store] in
      do {
        guard let store else { return }
        let isKept = try await dependency.keepRepository.isKept(episodeID: store.state.episode.id)
        guard !Task.isCancelled else { return }
        var state = store.state
        state.isKept = isKept
        state.keepErrorMessage = nil
        store.state = state
      } catch {
        guard !Task.isCancelled, let store else { return }
        var state = store.state
        state.keepErrorMessage = error.localizedDescription
        store.state = state
      }
    }
  }

  private func toggleKeep() {
    guard let wasKept = store.state.isKept,
          !store.state.isUpdatingKeep else {
      return
    }

    keepTask?.cancel()
    var state = store.state
    state.isKept = !wasKept
    state.isUpdatingKeep = true
    state.keepErrorMessage = nil
    store.state = state

    keepTask = Task { [dependency, weak store] in
      guard let store else { return }
      do {
        if wasKept {
          try await dependency.keepRepository.unkeep(episodeID: store.state.episode.id)
        } else {
          try await dependency.keepRepository.keep(store.state.episode)
        }
        guard !Task.isCancelled else { return }
        var state = store.state
        state.isUpdatingKeep = false
        store.state = state
      } catch {
        guard !Task.isCancelled else { return }
        var state = store.state
        state.isKept = wasKept
        state.isUpdatingKeep = false
        state.keepErrorMessage = error.localizedDescription
        store.state = state
      }
    }
  }
}
