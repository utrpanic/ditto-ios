@MainActor
protocol TopPodcastsPresentable: AnyObject {}

@MainActor
protocol TopPodcastsInteractable: AnyObject {
  var state: TopPodcastsState { get }
}

public protocol TopPodcastsDependency: Sendable {}

@MainActor
final class TopPodcastsInteractor: TopPodcastsInteractable {
  private(set) var state = TopPodcastsState()
  private let dependency: TopPodcastsDependency
  weak var presenter: TopPodcastsPresentable?
  weak var listener: TopPodcastsListener?

  init(dependency: TopPodcastsDependency) {
    self.dependency = dependency
  }
}
