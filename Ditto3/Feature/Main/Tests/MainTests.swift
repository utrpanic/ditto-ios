import Discover
import Entity
import Episode
import Latest
import Library
import Player
import Repository
import RIBsLite
import Search
import Testing
import UIKit
@testable import Main

struct MainTests {
  @MainActor
  @Test
  func builderActivatesAfterConnectingDependencies() {
    let playerBuilder = PlayerBuildableSpy(viewController: UIViewController())
    let builder = MainBuilder(dependency: MainDependencyStub(playerBuilder: playerBuilder))
    let (result, _) = builder.build(listener: nil)
    let viewController = result.ui

    #expect(playerBuilder.buildCallCount == 1)
    viewController.loadViewIfNeeded()
    viewController.loadViewIfNeeded()
    #expect((viewController as? MainViewController)?.tabs.count == 4)
    #expect(playerBuilder.buildCallCount == 1)
  }

  @MainActor
  @Test
  func activationConfiguresChildrenAfterRouterConnection() {
    let playerBuilder = PlayerBuildableSpy(viewController: UIViewController())
    let interactor = MainInteractor()
    let viewController = MainViewController(interactor: interactor)
    let router = MainRouter(
      dependency: MainDependencyStub(playerBuilder: playerBuilder),
      viewController: viewController
    )
    interactor.router = router
    viewController.loadViewIfNeeded()
    #expect(playerBuilder.buildCallCount == 0)

    interactor.activate()

    #expect(viewController.tabs.count == 4)
    #expect(playerBuilder.listener === interactor)
    router.selectTab(.search)
    viewController.loadViewIfNeeded()
    #expect(viewController.selectedTab === viewController.tabs[3])
    #expect(playerBuilder.buildCallCount == 1)
  }

  @MainActor
  @Test
  func selectingTabDoesNotCreateChildren() {
    let playerBuilder = PlayerBuildableSpy(viewController: UIViewController())
    let interactor = MainInteractor()
    let viewController = MainViewController(interactor: interactor)
    viewController.loadViewIfNeeded()
    let router = MainRouter(
      dependency: MainDependencyStub(playerBuilder: playerBuilder),
      viewController: viewController
    )

    router.selectTab(.latest)

    #expect(viewController.tabs.isEmpty)
    #expect(playerBuilder.buildCallCount == 0)
    #expect(interactor.store.state.selectedTab == .latest)
  }

  @MainActor
  @Test
  func externalNavigationWorksAfterInitialConfiguration() throws {
    let playerBuilder = PlayerBuildableSpy(viewController: UIViewController())
    let builder = MainBuilder(dependency: MainDependencyStub(playerBuilder: playerBuilder))
    let (result, navigation) = builder.build(listener: nil)
    let viewController = try #require(result.ui as? MainViewController)
    viewController.loadViewIfNeeded()
    let destination = UIViewController()

    navigation.selectTab(.search)
    navigation.push(destination)

    #expect(viewController.selectedTab === viewController.tabs[3])
    #expect((viewController.selectedViewController as? UINavigationController)?.topViewController === destination)
    #expect(playerBuilder.buildCallCount == 1)
  }

  @MainActor
  @Test
  func retainedRouterDoesNotKeepChildrenAliveAfterMainRelease() {
    var router: MainRouter?
    weak var discoverViewController: UIViewController?
    weak var playerViewController: UIViewController?
    autoreleasepool {
      let interactor = MainInteractor()
      let viewController = MainViewController(interactor: interactor)
      router = MainRouter(dependency: MainDependencyStub(), viewController: viewController)
      interactor.router = router
      interactor.activate()
      viewController.loadViewIfNeeded()
      discoverViewController = (viewController.selectedViewController as? UINavigationController)?.viewControllers.first
      playerViewController = viewController.children.first { $0 is PlayerViewControllerStub }
      #expect(discoverViewController != nil)
      #expect(playerViewController != nil)
    }

    #expect(router != nil)
    #expect(router?.viewController == nil)
    #expect(discoverViewController == nil)
    #expect(playerViewController == nil)
  }

  @MainActor
  @Test
  func stateChangesSynchronouslyUpdateSelectedTab() {
    let interactor = MainInteractor()
    let viewController = MainViewController(interactor: interactor)
    viewController.loadViewIfNeeded()
    viewController.attachDiscoverTab(UIViewController())
    viewController.attachLatestTab(UIViewController())
    viewController.attachLibraryTab(UIViewController())
    viewController.attachSearchTab(UIViewController())

    for (tab, index) in [(MainTab.latest, 1), (.library, 2), (.search, 3), (.discover, 0)] {
      interactor.sendAction(.selectTab(tab))
      #expect(viewController.selectedTab === viewController.tabs[index])
    }

    interactor.sendAction(.selectTab(.latest))
    interactor.sendAction(.selectTab(.search))
    #expect(viewController.selectedTab === viewController.tabs[3])
  }

  @MainActor
  @Test
  func stateSubscriptionDoesNotRetainMainViewControllerOrInteractor() {
    weak var weakViewController: MainViewController?
    weak var weakInteractor: MainInteractor?
    let store = autoreleasepool {
      let interactor = MainInteractor()
      let viewController = MainViewController(interactor: interactor)
      weakViewController = viewController
      weakInteractor = interactor
      viewController.loadViewIfNeeded()
      interactor.store.state.selectedTab = .latest
      return interactor.store
    }

    #expect(weakViewController == nil)
    #expect(weakInteractor == nil)
    store.state.selectedTab = .search
  }

  @MainActor
  @Test func sendSelectTabAction_updatesSelectedTab() async throws {
    let interactor = MainInteractor()

    interactor.sendAction(.selectTab(.search))

    #expect(interactor.store.state.selectedTab == .search)
  }

  @MainActor
  @Test
  func initialConfigurationAttachesChildrenOnlyOnce() {
    let playerViewController = PlayerViewControllerStub()
    let playerBuilder = PlayerBuildableSpy(viewController: playerViewController)
    let dependency = MainDependencyStub(playerBuilder: playerBuilder)
    let interactor = MainInteractor()
    let mainViewController = MainViewController(interactor: interactor)
    let router = MainRouter(
      dependency: dependency,
      viewController: mainViewController
    )
    interactor.router = router
    interactor.activate()
    mainViewController.loadViewIfNeeded()

    router.selectTab(.latest)
    mainViewController.loadViewIfNeeded()
    router.attachPlayer(listener: MainInteractor())

    #expect(playerBuilder.buildCallCount == 1)
    #expect(playerBuilder.listener === interactor)
    #expect(mainViewController.tabs.count == 4)
    #expect(interactor.store.state.selectedTab == .latest)
    #expect(playerViewController.parent === mainViewController)
    #expect(mainViewController.bottomAccessory == nil)

    playerBuilder.listener?.playerVisibilityDidChange(true)

    #expect(mainViewController.bottomAccessory?.contentView === playerViewController.view)

    playerBuilder.listener?.playerVisibilityDidChange(false)
    #expect(mainViewController.bottomAccessory == nil)
  }

  @MainActor
  @Test
  func routingAfterViewControllerReleaseDoesNotCrash() {
    let playerBuilder = PlayerBuildableSpy(viewController: UIViewController())
    let dependency = MainDependencyStub(playerBuilder: playerBuilder)
    let interactor = MainInteractor()
    var viewController: MainViewController? = MainViewController(interactor: interactor)
    let router = MainRouter(
      dependency: dependency,
      viewController: viewController!
    )
    viewController = nil

    router.attachPlayer(listener: interactor)
    router.selectTab(.discover)
    router.push(UIViewController())

    #expect(router.viewController == nil)
    #expect(playerBuilder.buildCallCount == 0)
  }

  @MainActor
  @Test
  func playerVisibilityReceivedBeforeAttachmentIsApplied() {
    let interactor = MainInteractor()
    interactor.playerVisibilityDidChange(true)
    let viewController = MainViewController(interactor: interactor)
    let playerViewController = UIViewController()
    viewController.loadViewIfNeeded()

    viewController.attachPlayer(playerViewController)

    #expect(viewController.bottomAccessory?.contentView === playerViewController.view)
    interactor.playerVisibilityDidChange(false)
    #expect(viewController.bottomAccessory == nil)
  }

  @MainActor
  @Test
  func playerEpisodeRequestPushesOnCurrentTab() {
    let episode = Episode(
      id: EpisodeID("next"),
      podcastTitle: "Architecture Talks",
      title: "Next episode",
      feedURL: URL(string: "https://example.com/feed.xml")!,
      audioURL: URL(string: "https://example.com/next.mp3")
    )
    let destination = UIViewController()
    let episodeBuilder = EpisodeBuildableSpy(destination: destination)
    let playerBuilder = PlayerBuildableSpy(viewController: UIViewController())
    let dependency = MainDependencyStub(playerBuilder: playerBuilder, episodeBuilder: episodeBuilder)
    let interactor = MainInteractor()
    let viewController = MainViewController(interactor: interactor)
    let router = MainRouter(
      dependency: dependency,
      viewController: viewController
    )
    interactor.router = router
    interactor.activate()
    viewController.loadViewIfNeeded()
    router.selectTab(.latest)

    playerBuilder.listener?.playerDidRequestEpisode(episode)

    let navigationController = viewController.selectedViewController as? UINavigationController
    #expect(episodeBuilder.builtEpisode == episode)
    #expect(viewController.selectedTab === viewController.tabs[1])
    #expect(navigationController?.topViewController === destination)
  }

  @MainActor
  @Test
  func mainViewControllerPushesOnCurrentTabNavigationStack() {
    let interactor = MainInteractor()
    let viewController = MainViewController(interactor: interactor)
    let discoverRoot = UIViewController()
    let latestRoot = UIViewController()
    let destination = UIViewController()
    viewController.loadViewIfNeeded()
    viewController.attachDiscoverTab(discoverRoot)
    viewController.attachLatestTab(latestRoot)

    viewController.selectTab(.latest)
    viewController.push(destination)

    let navigationController = viewController.selectedViewController as? UINavigationController
    #expect(navigationController?.viewControllers.first === latestRoot)
    #expect(navigationController?.topViewController === destination)
  }
}

private struct MainDependencyStub: MainDependency {
  let episodeBuilder: EpisodeBuildable
  let discoverBuilder: DiscoverBuildable = DiscoverBuildableStub()
  let latestBuilder: LatestBuildable = LatestBuildableStub()
  let libraryBuilder: LibraryBuildable = LibraryBuildableStub()
  let playerBuilder: PlayerBuildable
  let searchBuilder: SearchBuildable = SearchBuildableStub()

  @MainActor
  init(playerBuilder: PlayerBuildable? = nil, episodeBuilder: EpisodeBuildable? = nil) {
    self.episodeBuilder = episodeBuilder ?? EpisodeBuildableSpy(destination: UIViewController())
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
    PlayerViewControllerStub()
  }
}

@MainActor
private final class PlayerBuildableSpy: PlayerBuildable {
  private let viewController: ViewControllable
  private(set) var buildCallCount = 0
  private(set) weak var listener: PlayerListener?

  init(viewController: ViewControllable) {
    self.viewController = viewController
  }

  func build(listener: PlayerListener?) -> ViewControllable {
    buildCallCount += 1
    self.listener = listener
    return viewController
  }
}

@MainActor
private final class PlayerViewControllerStub: UIViewController {}

@MainActor
private final class EpisodeBuildableSpy: EpisodeBuildable {
  private let destination: ViewControllable
  private(set) var builtEpisode: Episode?

  init(destination: ViewControllable) {
    self.destination = destination
  }

  func build(episode: Episode, listener: EpisodeListener?) -> ViewControllable {
    builtEpisode = episode
    return destination
  }
}
