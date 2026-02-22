import UIKit

public final class TopPodcastsBuilder: TopPodcastsBuildable {
  private let dependency: TopPodcastsDependency

  public init(dependency: TopPodcastsDependency) {
    self.dependency = dependency
  }

  @MainActor
  public func build(listener: TopPodcastsListener?) -> UIViewController {
    let interactor = TopPodcastsInteractor(dependency: dependency)
    let viewController = TopPodcastsViewController(interactor: interactor)
    interactor.presenter = viewController
    interactor.listener = listener
    return viewController
  }
}
