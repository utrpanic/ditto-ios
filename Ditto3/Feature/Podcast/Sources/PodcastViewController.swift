import Entity
import UIKit

@MainActor
final class PodcastViewController: UIViewController {
  let podcast: Podcast

  init(podcast: Podcast) {
    self.podcast = podcast
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = podcast.title
    label.font = .systemFont(ofSize: 28, weight: .semibold)
    label.textAlignment = .center

    view.addSubview(label)

    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}
