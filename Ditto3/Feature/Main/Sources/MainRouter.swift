import Discover
import Latest
import Library
import Player
import RIBsLite
import Search
import UIKit

@MainActor
protocol MainViewControllable: ViewControllable {
  func attachDiscoverTab(_ viewController: ViewControllable)
  func attachLatestTab(_ viewController: ViewControllable)
  func attachLibraryTab(_ viewController: ViewControllable)
  func attachSearchTab(_ viewController: ViewControllable)
  func attachPlayer(_ viewController: PlayerViewControllable)
  func selectTab(_ tab: MainTabDestination)
  func push(_ viewController: ViewControllable)
}

@MainActor
final class MainRouter: Router<MainViewControllable>, MainRouting {
  private weak var interactor: MainInteractable?
  private let discoverBuilder: DiscoverBuildable
  private var discoverViewController: ViewControllable?
  private let latestBuilder: LatestBuildable
  private var latestViewController: ViewControllable?
  private let libraryBuilder: LibraryBuildable
  private var libraryViewController: ViewControllable?
  private let searchBuilder: SearchBuildable
  private var searchViewController: ViewControllable?
  private let playerBuilder: PlayerBuildable
  private var playerViewController: PlayerViewControllable?

  init(
    dependency: MainDependency,
    interactor: MainInteractable,
    viewController: MainViewControllable
  ) {
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
    viewController.selectTab(tab)
  }

  func push(_ viewController: ViewControllable) {
    self.viewController.push(viewController)
  }

  private func attachDiscoverIfNeeded() {
    guard discoverViewController == nil else { return }
    let viewController = discoverBuilder.build(listener: interactor)
    discoverViewController = viewController
    self.viewController.attachDiscoverTab(viewController)
  }

  private func attachLatestIfNeeded() {
    guard latestViewController == nil else { return }
    let viewController = latestBuilder.build(listener: interactor)
    latestViewController = viewController
    self.viewController.attachLatestTab(viewController)
  }

  private func attachLibraryIfNeeded() {
    guard libraryViewController == nil else { return }
    let viewController = libraryBuilder.build(listener: interactor)
    libraryViewController = viewController
    self.viewController.attachLibraryTab(viewController)
  }

  private func attachSearchIfNeeded() {
    guard searchViewController == nil else { return }
    let viewController = searchBuilder.build(listener: interactor)
    searchViewController = viewController
    self.viewController.attachSearchTab(viewController)
  }

  private func attachPlayerIfNeeded() {
    guard playerViewController == nil else { return }
    let viewController = playerBuilder.build(listener: interactor)
    playerViewController = viewController
    self.viewController.attachPlayer(viewController)
  }
}
