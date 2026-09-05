import Entity
@testable import Podcast
import Testing

struct PodcastTests {
  @MainActor
  @Test
  func buildPassesPodcastToViewController() throws {
    let podcast = Podcast(
      id: PodcastID(42),
      title: "Architecture Talks",
      author: "KeepCast"
    )
    let builder = PodcastBuilder(dependency: Dependency())

    let result = builder.build(podcast: podcast, listener: nil)

    let viewController = try #require(result as? PodcastViewController)
    #expect(viewController.podcast == podcast)
  }
}

private struct Dependency: PodcastDependency {}
