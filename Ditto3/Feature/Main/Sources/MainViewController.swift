import Combine
import RIBsLite
import UIKit

@MainActor
protocol MainInteractable: AnyObject {
  var store: MainStateStore { get }
}

@MainActor
final class MainViewController: UITabBarController, MainViewControllable, UITabBarControllerDelegate {
  private let interactor: MainInteractable
  weak var listener: MainPresentableListener?
  
  private var topPodcastsTabViewController: UIViewController?
  private var newTabViewController: UIViewController?
  private var bookmarksTabViewController: UIViewController?
  private var searchTabViewController: UIViewController?
  
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
    let viewController: UIViewController? = switch tab {
    case .topPodcasts:
      topPodcastsTabViewController
    case .new:
      newTabViewController
    case .bookmarks:
      bookmarksTabViewController
    case .search:
      searchTabViewController
    }
    guard let viewController else { return }
    selectedViewController = viewController
  }

  // MARK: - MainViewControllable

  func attachTopPodcastsTab(_ viewController: UIViewController) {
    let navigationController = makeTabNavigationController(
      rootViewController: viewController,
      title: "Top",
      image: UIImage(systemName: "music.note.list")
    )
    topPodcastsTabViewController = navigationController
    appendTab(navigationController)
  }

  func attachNewTab(_ viewController: UIViewController) {
    let navigationController = makeTabNavigationController(
      rootViewController: viewController,
      title: "New",
      image: UIImage(systemName: "sparkles")
    )
    newTabViewController = navigationController
    appendTab(navigationController)
  }

  func attachBookmarksTab(_ viewController: UIViewController) {
    let navigationController = makeTabNavigationController(
      rootViewController: viewController,
      title: "Bookmarks",
      image: UIImage(systemName: "bookmark")
    )
    bookmarksTabViewController = navigationController
    appendTab(navigationController)
  }

  func attachSearchTab(_ viewController: UIViewController) {
    let navigationController = makeTabNavigationController(
      rootViewController: viewController,
      title: "Search",
      image: UIImage(systemName: "magnifyingglass")
    )
    searchTabViewController = navigationController
    appendTab(navigationController)
  }

  private func makeTabNavigationController(
    rootViewController: UIViewController,
    title: String,
    image: UIImage?
  ) -> UIViewController {
    rootViewController.title = title
    rootViewController.tabBarItem = UITabBarItem(title: title, image: image, selectedImage: image)
    return UINavigationController(rootViewController: rootViewController)
  }

  private func appendTab(_ viewController: UIViewController) {
    var viewControllers = viewControllers ?? []
    viewControllers.append(viewController)
    setViewControllers(viewControllers, animated: false)
  }

  // MARK: - UITabBarControllerDelegate

  func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
    let tab: MainTab? = switch viewController {
    case topPodcastsTabViewController:
      .topPodcasts
    case newTabViewController:
      .new
    case bookmarksTabViewController:
      .bookmarks
    case searchTabViewController:
      .search
    default:
      nil
    }
    guard let tab else { return }
    listener?.didSelectTab(tab)
  }
}
