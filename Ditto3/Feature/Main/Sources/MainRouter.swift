import Discover
import Entity
import Episode
import Latest
import Library
import Player
import RIBsLite
import Search

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
  private weak var interactor: MainInteractable?
  private let episodeBuilder: EpisodeBuildable
  private let discoverBuilder: DiscoverBuildable
  private var discoverViewController: ViewControllable?
  private let latestBuilder: LatestBuildable
  private var latestViewController: ViewControllable?
  private let libraryBuilder: LibraryBuildable
  private var libraryViewController: ViewControllable?
  private let searchBuilder: SearchBuildable
  private var searchViewController: ViewControllable?
  private let playerBuilder: PlayerBuildable
  private var playerViewController: ViewControllable?

  init(
    dependency: MainDependency,
    interactor: MainInteractable,
    viewController: MainViewControllable
  ) {
    self.episodeBuilder = dependency.episodeBuilder
    self.interactor = interactor
    self.discoverBuilder = dependency.discoverBuilder
    self.latestBuilder = dependency.latestBuilder
    self.libraryBuilder = dependency.libraryBuilder
    self.searchBuilder = dependency.searchBuilder
    self.playerBuilder = dependency.playerBuilder
    super.init(viewController: viewController)
  }

  func routeToMain(tab: MainTabDestination) {
    attachDiscoverIfNeeded()
    attachLatestIfNeeded()
    attachLibraryIfNeeded()
    attachSearchIfNeeded()
    attachPlayerIfNeeded()
    viewController?.selectTab(tab)
  }

  func routeToEpisode(_ episode: Entity.Episode) {
    let episodeViewController = episodeBuilder.build(episode: episode, listener: nil)
    viewController?.push(episodeViewController)
  }

  func push(_ viewController: ViewControllable) {
    self.viewController?.push(viewController)
  }

  private func attachDiscoverIfNeeded() {
    guard discoverViewController == nil else { return }
    let viewController = discoverBuilder.build(listener: interactor)
    discoverViewController = viewController
    self.viewController?.attachDiscoverTab(viewController)
  }

  private func attachLatestIfNeeded() {
    guard latestViewController == nil else { return }
    let viewController = latestBuilder.build(listener: interactor)
    latestViewController = viewController
    self.viewController?.attachLatestTab(viewController)
  }

  private func attachLibraryIfNeeded() {
    guard libraryViewController == nil else { return }
    let viewController = libraryBuilder.build(listener: interactor)
    libraryViewController = viewController
    self.viewController?.attachLibraryTab(viewController)
  }

  private func attachSearchIfNeeded() {
    guard searchViewController == nil else { return }
    let viewController = searchBuilder.build(listener: interactor)
    searchViewController = viewController
    self.viewController?.attachSearchTab(viewController)
  }

  private func attachPlayerIfNeeded() {
    guard playerViewController == nil else { return }
    let viewController = playerBuilder.build(listener: interactor)
    playerViewController = viewController
    self.viewController?.attachPlayer(viewController)
  }
}
