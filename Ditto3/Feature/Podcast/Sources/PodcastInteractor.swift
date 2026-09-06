import Entity
import Foundation
import Repository
import RIBsLite

enum PodcastAction {
  case retry
  case selectEpisode(Episode)
}

@MainActor
protocol PodcastInteractable: AnyObject {
  var store: StateStore<PodcastState> { get }
  func sendAction(_ action: PodcastAction)
}

@MainActor
final class PodcastInteractor: Interactor, PodcastInteractable {
  private let dependency: PodcastDependency
  private let podcast: Podcast
  let store: StateStore<PodcastState>
  var router: PodcastRouting?
  weak var listener: PodcastListener?

  private var loadTask: Task<Void, Never>?

  init(podcast: Podcast, dependency: PodcastDependency) {
    self.podcast = podcast
    self.dependency = dependency
    self.store = StateStore(.loading(podcast: podcast))
    super.init()
  }

  override func didBecomeActive() {
    loadEpisodes()
  }

  func sendAction(_ action: PodcastAction) {
    switch action {
    case .retry:
      loadEpisodes()
    case .selectEpisode(let episode):
      router?.routeToEpisode(episode)
    }
  }

  private func loadEpisodes() {
    loadTask?.cancel()
    loadTask = Task { [dependency, podcast, weak store] in
      store?.state = .loading(podcast: podcast)
      do {
        let feedURL: URL
        if let knownFeedURL = podcast.feedURL {
          feedURL = knownFeedURL
        } else {
          feedURL = try await dependency.podcastRepository.resolveFeedURL(podcastID: podcast.id)
        }
        let episodes = try await dependency.episodeRepository.fetchEpisodes(
          podcast: podcast,
          feedURL: feedURL,
          limit: 20
        )
        guard !Task.isCancelled else { return }
        store?.state = .loaded(podcast: podcast, episodes: episodes)
      } catch {
        guard !Task.isCancelled else { return }
        store?.state = .failed(podcast: podcast, message: error.localizedDescription)
      }
    }
  }
}
