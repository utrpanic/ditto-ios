import Entity
import Playback
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

  init(episode: Episode, dependency: EpisodeDependency) {
    self.store = StateStore(EpisodeState(episode: episode))
    self.playbackController = dependency.playbackController
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
    }
  }
}
