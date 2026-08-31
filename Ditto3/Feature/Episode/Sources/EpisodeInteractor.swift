import Combine
import Entity
import RIBsLite

@MainActor
protocol EpisodeInteractable: AnyObject {
  var store: EpisodeStateStore { get }
}

final class EpisodeStateStore: ObservableObject {
  @Published fileprivate(set) var state: EpisodeState

  init(initialState: EpisodeState) {
    self.state = initialState
  }
}

@MainActor
final class EpisodeInteractor: Interactor, EpisodeInteractable {
  let store: EpisodeStateStore
  var router: EpisodeRouting?
  weak var listener: EpisodeListener?

  init(episode: Episode) {
    self.store = EpisodeStateStore(initialState: EpisodeState(episode: episode))
    super.init()
  }
}
