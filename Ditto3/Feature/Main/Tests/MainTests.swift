import Entity
import Repository
import Discover
import Latest
import Library
@testable import Main
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
}

private struct MainDependencyStub: MainDependency {
  let discoverBuilder: DiscoverBuildable = DiscoverBuildableStub()
  let latestBuilder: LatestBuildable = LatestBuildableStub()
  let libraryBuilder: LibraryBuildable = LibraryBuildableStub()
  let searchBuilder: SearchBuildable = SearchBuildableStub()
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
