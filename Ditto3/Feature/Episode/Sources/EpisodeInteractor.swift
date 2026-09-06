import Entity
import RIBsLite

@MainActor
protocol EpisodeInteractable: AnyObject {
  var store: StateStore<EpisodeState> { get }
}

@MainActor
final class EpisodeInteractor: Interactor, EpisodeInteractable {
  let store: StateStore<EpisodeState>
  var router: EpisodeRouting?
  weak var listener: EpisodeListener?

  init(episode: Episode) {
    self.store = StateStore(EpisodeState(episode: episode))
    super.init()
  }
}
