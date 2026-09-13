import Discover
import Latest
import Library
import RIBsLite
import Search
import UIKit

@MainActor
protocol MainViewControllable: ViewControllable {
  func attachDiscoverTab(_ viewController: ViewControllable)
  func attachLatestTab(_ viewController: ViewControllable)
  func attachLibraryTab(_ viewController: ViewControllable)
  func attachSearchTab(_ viewController: ViewControllable)
}

@MainActor
protocol MainRouting: Routing {
  func attachDiscover(listener: DiscoverListener?)
  func attachLatest(listener: LatestListener?)
  func attachLibrary(listener: LibraryListener?)
  func attachSearch(listener: SearchListener?)
}

@MainActor
final class MainRouter: Router<MainViewControllable>, MainRouting {
  private let discoverBuilder: DiscoverBuildable
  private var discoverViewController: ViewControllable?
  private let latestBuilder: LatestBuildable
  private var latestViewController: ViewControllable?
  private let libraryBuilder: LibraryBuildable
  private var libraryViewController: ViewControllable?
  private let searchBuilder: SearchBuildable
  private var searchViewController: ViewControllable?

  init(dependency: MainDependency, viewController: MainViewControllable) {
    self.discoverBuilder = dependency.discoverBuilder
    self.latestBuilder = dependency.latestBuilder
    self.libraryBuilder = dependency.libraryBuilder
    self.searchBuilder = dependency.searchBuilder
    super.init(viewController: viewController)
  }

  func attachDiscover(listener: DiscoverListener?) {
    guard discoverViewController == nil else { return }
    let viewController = discoverBuilder.build(listener: listener)
    discoverViewController = viewController
    self.viewController.attachDiscoverTab(viewController)
  }

  func attachLatest(listener: LatestListener?) {
    guard latestViewController == nil else { return }
    let viewController = latestBuilder.build(listener: listener)
    latestViewController = viewController
    self.viewController.attachLatestTab(viewController)
  }

  func attachLibrary(listener: LibraryListener?) {
    guard libraryViewController == nil else { return }
    let viewController = libraryBuilder.build(listener: listener)
    libraryViewController = viewController
    self.viewController.attachLibraryTab(viewController)
  }

  func attachSearch(listener: SearchListener?) {
    guard searchViewController == nil else { return }
    let viewController = searchBuilder.build(listener: listener)
    searchViewController = viewController
    self.viewController.attachSearchTab(viewController)
  }
}
