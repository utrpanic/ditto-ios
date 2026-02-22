import UIKit

@MainActor
final class TopPodcastsViewController: UIViewController, TopPodcastsPresentable {
  private let interactor: TopPodcastsInteractable
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let stackView = UIStackView()

  init(interactor: TopPodcastsInteractable) {
    self.interactor = interactor
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "Top Podcasts"
    setupUI()
    render(state: interactor.state)
  }

  private func render(state: TopPodcastsState) {
    titleLabel.text = state.title
  }

  private func setupUI() {
    view.backgroundColor = .systemBackground

    titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.textColor = .label

    subtitleLabel.font = .preferredFont(forTextStyle: .body)
    subtitleLabel.adjustsFontForContentSizeCategory = true
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0
    subtitleLabel.text = "Top Podcasts 화면을 UIKit으로 먼저 구성합니다."

    stackView.axis = .vertical
    stackView.alignment = .fill
    stackView.spacing = 12
    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(subtitleLabel)

    view.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
      stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
    ])
  }
}
