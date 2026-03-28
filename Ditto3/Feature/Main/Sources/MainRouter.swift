import Bookmarks
import New
import RIBsLite
import Search
import TopPodcasts
import UIKit

@MainActor
protocol MainViewControllable: ViewControllable {
  func attachTopPodcastsTab(_ viewController: UIViewController)
  func attachNewTab(_ viewController: UIViewController)
  func attachBookmarksTab(_ viewController: UIViewController)
  func attachSearchTab(_ viewController: UIViewController)
}

@MainActor
final class MainRouter: Router<MainDependency, MainViewControllable> {
  func attachTopPodcasts(listener: TopPodcastsListener?) {
    viewController.attachTopPodcastsTab(
      dependency.topPodcastsBuildable.build(listener: listener),
    )
  }

  func attachNew(listener: NewListener?) {
    viewController.attachNewTab(
      dependency.newBuildable.build(listener: listener),
    )
  }

  func attachBookmarks(listener: BookmarksListener?) {
    viewController.attachBookmarksTab(
      dependency.bookmarksBuildable.build(listener: listener),
    )
  }

  func attachSearch(listener: SearchListener?) {
    viewController.attachSearchTab(
      dependency.searchBuildable.build(listener: listener),
    )
  }
}
