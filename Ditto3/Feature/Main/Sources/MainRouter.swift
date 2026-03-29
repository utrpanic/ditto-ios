import Bookmarks
import New
import RIBsLite
import Search
import TopPodcasts
import UIKit

@MainActor
protocol MainViewControllable: ViewControllable {
  func attachTopPodcastsTab(_ viewController: ViewControllable)
  func attachNewTab(_ viewController: ViewControllable)
  func attachBookmarksTab(_ viewController: ViewControllable)
  func attachSearchTab(_ viewController: ViewControllable)
}

@MainActor
protocol MainRouting: Routing {
  func attachTopPodcasts(listener: TopPodcastsListener?)
  func attachNew(listener: NewListener?)
  func attachBookmarks(listener: BookmarksListener?)
  func attachSearch(listener: SearchListener?)
}

@MainActor
final class MainRouter: Router<MainViewControllable>, MainRouting {
  private let topPodcastsBuilder: TopPodcastsBuildable
  private var topPodcastsViewController: ViewControllable?

  private let newBuilder: NewBuildable
  private var newViewController: ViewControllable?

  private let bookmarksBuilder: BookmarksBuildable
  private var bookmarksViewController: ViewControllable?

  private let searchBuilder: SearchBuildable
  private var searchViewController: ViewControllable?

  init(dependency: MainDependency, viewController: MainViewControllable) {
    self.topPodcastsBuilder = dependency.topPodcastsBuilder
    self.newBuilder = dependency.newBuilder
    self.bookmarksBuilder = dependency.bookmarksBuilder
    self.searchBuilder = dependency.searchBuilder
    super.init(viewController: viewController)
  }

  func attachTopPodcasts(listener: TopPodcastsListener?) {
    guard topPodcastsViewController == nil else { return }
    let viewController = topPodcastsBuilder.build(listener: listener)
    topPodcastsViewController = viewController
    self.viewController.attachTopPodcastsTab(viewController)
  }

  func attachNew(listener: NewListener?) {
    guard newViewController == nil else { return }
    let viewController = newBuilder.build(listener: listener)
    newViewController = viewController
    self.viewController.attachNewTab(viewController)
  }

  func attachBookmarks(listener: BookmarksListener?) {
    guard bookmarksViewController == nil else { return }
    let viewController = bookmarksBuilder.build(listener: listener)
    bookmarksViewController = viewController
    self.viewController.attachBookmarksTab(viewController)
  }

  func attachSearch(listener: SearchListener?) {
    guard searchViewController == nil else { return }
    let viewController = searchBuilder.build(listener: listener)
    searchViewController = viewController
    self.viewController.attachSearchTab(viewController)
  }
}
