import Combine
import RIBsLite
import UIKit

@MainActor
protocol MainInteractable: AnyObject {
  var store: MainStateStore { get }
}

@MainActor
final class MainViewController: UITabBarController, MainViewControllable, UITabBarControllerDelegate {
  private enum TabIdentifier {
    static let topPodcasts = "main.top-podcasts"
    static let new = "main.new"
    static let bookmarks = "main.bookmarks"
    static let search = "main.search"
  }

  private let interactor: MainInteractable
  weak var listener: MainPresentableListener?
  
  private var topPodcastsTab: UITab?
  private var newTab: UITab?
  private var bookmarksTab: UITab?
  private var searchTab: UISearchTab?
  
  private var cancellables = Set<AnyCancellable>()

  init(interactor: MainInteractable, listener: MainPresentableListener?) {
    self.interactor = interactor
    self.listener = listener
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    delegate = self
    bindState()
  }

  private func bindState() {
    let store = interactor.store
    render(state: store.state)
    store.$state
      .removeDuplicates()
      .sink { [weak self] state in
        self?.render(state: state)
      }
      .store(in: &cancellables)
  }

  private func render(state: MainState) {
    selectTab(state.selectedTab)
  }

  private func selectTab(_ tab: MainTab) {
    let selectedTab: UITab? = switch tab {
    case .topPodcasts:
      topPodcastsTab
    case .new:
      newTab
    case .bookmarks:
      bookmarksTab
    case .search:
      searchTab
    }
    guard let selectedTab else { return }
    self.selectedTab = selectedTab
  }

  // MARK: - MainViewControllable

  func attachTopPodcastsTab(_ viewController: ViewControllable) {
    let navigationController = UINavigationController(rootViewController: viewController.ui)
    let tab = UITab(
      title: "Top",
      image: UIImage(systemName: "music.note.list"),
      identifier: String(describing: MainTab.topPodcasts),
      viewControllerProvider: { _ in navigationController }
    )
    topPodcastsTab = tab
    appendTab(tab)
  }

  func attachNewTab(_ viewController: ViewControllable) {
    let navigationController = UINavigationController(rootViewController: viewController.ui)
    let tab = UITab(
      title: "New",
      image: UIImage(systemName: "sparkles"),
      identifier: String(describing: MainTab.new),
      viewControllerProvider: { _ in navigationController }
    )
    newTab = tab
    appendTab(tab)
  }

  func attachBookmarksTab(_ viewController: ViewControllable) {
    let navigationController = UINavigationController(rootViewController: viewController.ui)
    let tab = UITab(
      title: "Bookmarks",
      image: UIImage(systemName: "bookmark"),
      identifier: String(describing: MainTab.bookmarks),
      viewControllerProvider: { _ in navigationController }
    )
    bookmarksTab = tab
    appendTab(tab)
  }

  func attachSearchTab(_ viewController: ViewControllable) {
    let navigationController = UINavigationController(rootViewController: viewController.ui)
    let tab = UISearchTab(viewControllerProvider: { _ in navigationController })
    searchTab = tab
    appendTab(tab)
  }

  private func appendTab(_ tab: UITab) {
    var tabs = tabs
    tabs.append(tab)
    setTabs(tabs, animated: false)
  }

  // MARK: - UITabBarControllerDelegate

  func tabBarController(_ tabBarController: UITabBarController, didSelectTab selectedTab: UITab, previousTab: UITab?) {
    let tab: MainTab?
    if selectedTab === topPodcastsTab {
      tab = .topPodcasts
    } else if selectedTab === newTab {
      tab = .new
    } else if selectedTab === bookmarksTab {
      tab = .bookmarks
    } else if selectedTab === searchTab {
      tab = .search
    } else {
      tab = nil
    }
    guard let tab else { return }
    listener?.didSelectTab(tab)
  }
}
