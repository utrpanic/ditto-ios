import Discover
import Entity
import Episode
import Latest
import Library
import Player
import RIBsLite
import Search

@MainActor
protocol MainRouting: MainNavigation {
  func routeToEpisode(_ episode: Episode)
  func attachDiscoverTab(listener: DiscoverListener)
  func attachLatestTab(listener: LatestListener)
  func attachLibraryTab(listener: LibraryListener)
  func attachSearchTab(listener: SearchListener)
  func attachPlayer(listener: PlayerListener)
}

@MainActor
protocol MainViewControllable: ViewControllable {
  func attachDiscoverTab(_ viewController: ViewControllable)
  func attachLatestTab(_ viewController: ViewControllable)
  func attachLibraryTab(_ viewController: ViewControllable)
  func attachSearchTab(_ viewController: ViewControllable)
  func attachPlayer(_ viewController: ViewControllable)
  func selectTab(_ tab: MainTabDestination)
  func push(_ viewController: ViewControllable)
}

@MainActor
final class MainRouter: Router<MainViewControllable>, MainRouting {
  private let episodeBuilder: EpisodeBuildable
  private let discoverBuilder: DiscoverBuildable
  private weak var discoverViewController: ViewControllable?
  private let latestBuilder: LatestBuildable
  private weak var latestViewController: ViewControllable?
  private let libraryBuilder: LibraryBuildable
  private weak var libraryViewController: ViewControllable?
  private let searchBuilder: SearchBuildable
  private weak var searchViewController: ViewControllable?
  private let playerBuilder: PlayerBuildable
  private weak var playerViewController: ViewControllable?

  init(
    dependency: MainDependency,
    viewController: MainViewControllable
  ) {
    self.episodeBuilder = dependency.episodeBuilder
    self.discoverBuilder = dependency.discoverBuilder
    self.latestBuilder = dependency.latestBuilder
    self.libraryBuilder = dependency.libraryBuilder
    self.searchBuilder = dependency.searchBuilder
    self.playerBuilder = dependency.playerBuilder
    super.init(viewController: viewController)
  }

  func selectTab(_ tab: MainTabDestination) {
    guard let viewController else { return }
    viewController.selectTab(tab)
  }

  func routeToEpisode(_ episode: Entity.Episode) {
    guard let viewController else { return }
    let episodeViewController = episodeBuilder.build(episode: episode, listener: nil)
    viewController.push(episodeViewController)
  }

  func push(_ viewController: ViewControllable) {
    guard let sourceViewController = self.viewController else { return }
    sourceViewController.push(viewController)
  }

  func attachDiscoverTab(listener: DiscoverListener) {
    guard discoverViewController == nil, let viewController else { return }
    let child = discoverBuilder.build(listener: listener)
    discoverViewController = child
    viewController.attachDiscoverTab(child)
  }

  func attachLatestTab(listener: LatestListener) {
    guard latestViewController == nil, let viewController else { return }
    let child = latestBuilder.build(listener: listener)
    latestViewController = child
    viewController.attachLatestTab(child)
  }

  func attachLibraryTab(listener: LibraryListener) {
    guard libraryViewController == nil, let viewController else { return }
    let child = libraryBuilder.build(listener: listener)
    libraryViewController = child
    viewController.attachLibraryTab(child)
  }

  func attachSearchTab(listener: SearchListener) {
    guard searchViewController == nil, let viewController else { return }
    let child = searchBuilder.build(listener: listener)
    searchViewController = child
    viewController.attachSearchTab(child)
  }

  func attachPlayer(listener: PlayerListener) {
    guard playerViewController == nil, let viewController else { return }
    let child = playerBuilder.build(listener: listener)
    playerViewController = child
    viewController.attachPlayer(child)
  }
}
