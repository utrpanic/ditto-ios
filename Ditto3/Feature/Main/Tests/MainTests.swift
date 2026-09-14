import Entity
import Repository
import Discover
import Latest
import Library
@testable import Main
import Player
import RIBsLite
import Search
import Testing
import UIKit

struct MainTests {
  @MainActor
  @Test func sendSelectTabAction_updatesSelectedTab() async throws {
    let interactor = MainInteractor(dependency: MainDependencyStub())

    interactor.sendAction(.selectTab(.search))

    #expect(interactor.store.state.selectedTab == .search)
  }

  @MainActor
  @Test
  func routerAttachesOnePersistentPlayerChild() {
    let playerViewController = UIViewController()
    playerViewController.preferredContentSize = CGSize(width: 0, height: 68)
    let playerBuilder = PlayerBuildableSpy(viewController: playerViewController)
    let dependency = MainDependencyStub(playerBuilder: playerBuilder)
    let interactor = MainInteractor(dependency: dependency)
    let mainViewController = MainViewController(interactor: interactor)
    let router = MainRouter(dependency: dependency, viewController: mainViewController)
    mainViewController.loadViewIfNeeded()

    router.attachPlayer(listener: nil)
    router.attachPlayer(listener: nil)

    #expect(playerBuilder.buildCallCount == 1)
    #expect(playerViewController.parent === mainViewController)
    #expect(playerViewController.view.superview === mainViewController.view)
  }
}

private struct MainDependencyStub: MainDependency {
  let discoverBuilder: DiscoverBuildable = DiscoverBuildableStub()
  let latestBuilder: LatestBuildable = LatestBuildableStub()
  let libraryBuilder: LibraryBuildable = LibraryBuildableStub()
  let playerBuilder: PlayerBuildable
  let searchBuilder: SearchBuildable = SearchBuildableStub()

  @MainActor
  init(playerBuilder: PlayerBuildable? = nil) {
    self.playerBuilder = playerBuilder ?? PlayerBuildableStub()
  }
}

private struct DiscoverBuildableStub: DiscoverBuildable {
  @MainActor
  func build(listener: DiscoverListener?) -> ViewControllable {
    UIViewController()
  }
}

private struct LatestBuildableStub: LatestBuildable {
  @MainActor
  func build(listener: LatestListener?) -> ViewControllable {
    UIViewController()
  }
}

private struct LibraryBuildableStub: LibraryBuildable {
  @MainActor
  func build(listener: LibraryListener?) -> ViewControllable {
    UIViewController()
  }
}

private struct SearchBuildableStub: SearchBuildable {
  @MainActor
  func build(listener: SearchListener?) -> ViewControllable {
    UIViewController()
  }
}

private struct PlayerBuildableStub: PlayerBuildable {
  @MainActor
  func build(listener: PlayerListener?) -> ViewControllable {
    UIViewController()
  }
}

@MainActor
private final class PlayerBuildableSpy: PlayerBuildable {
  private let viewController: ViewControllable
  private(set) var buildCallCount = 0

  init(viewController: ViewControllable) {
    self.viewController = viewController
  }

  func build(listener: PlayerListener?) -> ViewControllable {
    buildCallCount += 1
    return viewController
  }
}
