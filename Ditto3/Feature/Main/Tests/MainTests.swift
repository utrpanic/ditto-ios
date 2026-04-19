import Entity
import Repository
import Bookmarks
@testable import Main
import New
import RIBsLite
import Search
import Testing
import TopPodcasts
import UIKit

struct MainTests {
  @MainActor
  @Test func sendSelectTabAction_updatesSelectedTab() async throws {
    let interactor = MainInteractor(dependency: MainDependencyStub())

    interactor.send(action: .selectTab(.search))

    #expect(interactor.store.state.selectedTab == .search)
  }
}

private struct MainDependencyStub: MainDependency {
  let topPodcastsBuilder: TopPodcastsBuildable = TopPodcastsBuildableStub()
  let newBuilder: NewBuildable = NewBuildableStub()
  let bookmarksBuilder: BookmarksBuildable = BookmarksBuildableStub()
  let searchBuilder: SearchBuildable = SearchBuildableStub()
}

private struct TopPodcastsBuildableStub: TopPodcastsBuildable {
  @MainActor
  func build(listener: TopPodcastsListener?) -> ViewControllable {
    UIViewController()
  }
}

private struct NewBuildableStub: NewBuildable {
  @MainActor
  func build(listener: NewListener?) -> ViewControllable {
    UIViewController()
  }
}

private struct BookmarksBuildableStub: BookmarksBuildable {
  @MainActor
  func build(listener: BookmarksListener?) -> ViewControllable {
    UIViewController()
  }
}

private struct SearchBuildableStub: SearchBuildable {
  @MainActor
  func build(listener: SearchListener?) -> ViewControllable {
    UIViewController()
  }
}
