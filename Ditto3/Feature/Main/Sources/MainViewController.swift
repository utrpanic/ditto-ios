import Combine
import RIBsLite
import UIKit

final class MainViewController: UITabBarController, MainViewControllable, UITabBarControllerDelegate {
  private enum TabIdentifier {
    static let discover = "main.discover"
    static let latest = "main.latest"
    static let library = "main.library"
    static let search = "main.search"
  }

  private let interactor: MainInteractable
  
  private var discoverTab: UITab?
  private var latestTab: UITab?
  private var libraryTab: UITab?
  private var searchTab: UISearchTab?
  private var playerAccessory: UITabAccessory?
  
  private var cancellables = Set<AnyCancellable>()

  init(interactor: MainInteractable) {
    self.interactor = interactor
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
    store.stateDidChange
      .removeDuplicates()
      .sink { [weak self] state in
        self?.render(state: state)
      }
      .store(in: &cancellables)
  }

  private func render(state: MainState) {
    renderSelectedTab(state.selectedTab)
    renderPlayerVisibility(state.isPlayerVisible)
  }

  private func renderSelectedTab(_ tab: MainTab) {
    let selectedTab: UITab? = switch tab {
    case .discover:
      discoverTab
    case .latest:
      latestTab
    case .library:
      libraryTab
    case .search:
      searchTab
    }
    guard let selectedTab else { return }
    self.selectedTab = selectedTab
  }

  // MARK: - MainViewControllable

  func attachDiscoverTab(_ viewController: ViewControllable) {
    let navigationController = UINavigationController(rootViewController: viewController.ui)
    let tab = UITab(
      title: "Discover",
      image: UIImage(systemName: "music.note.list"),
      identifier: TabIdentifier.discover,
      viewControllerProvider: { _ in navigationController }
    )
    discoverTab = tab
    appendTab(tab)
  }

  func attachLatestTab(_ viewController: ViewControllable) {
    let navigationController = UINavigationController(rootViewController: viewController.ui)
    let tab = UITab(
      title: "Latest",
      image: UIImage(systemName: "sparkles"),
      identifier: TabIdentifier.latest,
      viewControllerProvider: { _ in navigationController }
    )
    latestTab = tab
    appendTab(tab)
  }

  func attachLibraryTab(_ viewController: ViewControllable) {
    let navigationController = UINavigationController(rootViewController: viewController.ui)
    let tab = UITab(
      title: "Library",
      image: UIImage(systemName: "square.stack"),
      identifier: TabIdentifier.library,
      viewControllerProvider: { _ in navigationController }
    )
    libraryTab = tab
    appendTab(tab)
  }

  func attachSearchTab(_ viewController: ViewControllable) {
    let navigationController = UINavigationController(rootViewController: viewController.ui)
    let tab = UISearchTab(viewControllerProvider: { _ in navigationController })
    searchTab = tab
    appendTab(tab)
  }

  func attachPlayer(_ viewController: ViewControllable) {
    addChild(viewController.ui)
    playerAccessory = UITabAccessory(contentView: viewController.ui.view)
    viewController.ui.didMove(toParent: self)
    renderPlayerVisibility(interactor.store.state.isPlayerVisible)
  }

  private func renderPlayerVisibility(_ isVisible: Bool) {
    guard let playerAccessory else { return }
    guard isVisible != (bottomAccessory != nil) else { return }
    setBottomAccessory(isVisible ? playerAccessory : nil, animated: view.window != nil)
  }

  func selectTab(_ tab: MainTabDestination) {
    interactor.sendAction(.selectTab(tab.mainTab))
  }

  func push(_ viewController: ViewControllable) {
    guard let navigationController = selectedViewController as? UINavigationController else { return }
    navigationController.pushViewController(viewController.ui, animated: true)
  }

  private func appendTab(_ tab: UITab) {
    var tabs = tabs
    tabs.append(tab)
    setTabs(tabs, animated: false)
  }

  // MARK: - UITabBarControllerDelegate

  func tabBarController(_ tabBarController: UITabBarController, didSelectTab selectedTab: UITab, previousTab: UITab?) {
    let tab: MainTab?
    if selectedTab === discoverTab {
      tab = .discover
    } else if selectedTab === latestTab {
      tab = .latest
    } else if selectedTab === libraryTab {
      tab = .library
    } else if selectedTab === searchTab {
      tab = .search
    } else {
      tab = nil
    }
    guard let tab else { return }
    interactor.sendAction(.selectTab(tab))
  }
}

private extension MainTabDestination {
  var mainTab: MainTab {
    switch self {
    case .discover: .discover
    case .latest: .latest
    case .library: .library
    case .search: .search
    }
  }
}
