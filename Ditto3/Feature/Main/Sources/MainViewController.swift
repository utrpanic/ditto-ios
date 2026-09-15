import Combine
import Player
import RIBsLite
import UIKit

@MainActor
protocol MainInteractable: AnyObject {
  var store: StateStore<MainState> { get }
  func sendAction(_ action: MainAction)
}

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
  private var playerViewController: PlayerViewControllable?
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

  func attachPlayer(_ viewController: PlayerViewControllable) {
    guard playerViewController == nil else { return }
    playerViewController = viewController

    let playerUI = viewController.ui
    addChild(playerUI)
    let accessory = UITabAccessory(contentView: playerUI.view)
    playerAccessory = accessory
    playerUI.didMove(toParent: self)

    viewController.observeVisibility { [weak self] isVisible in
      guard let self else { return }
      guard isVisible != (bottomAccessory != nil) else { return }
      setBottomAccessory(isVisible ? accessory : nil, animated: view.window != nil)
    }
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
