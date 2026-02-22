import Foundation
import Testing
import Platform
@testable import Core

struct PodcastRepositoryOnLiveTests {
  @Test
  func searchPodcasts_liveAPI_returnsNonEmptyResults() async throws {
    let repository = PodcastRepositoryImp(session: URLSession.shared)

    let podcasts = try await repository.searchPodcasts(query: "swift")

    #expect(!podcasts.isEmpty)
    let first = try #require(podcasts.first)
    #expect(!first.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    #expect(!first.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }

  @Test
  func fetchTopPodcasts_liveAPI_respectsLimitRange() async throws {
    let repository = PodcastRepositoryImp(session: URLSession.shared)

    let podcasts = try await repository.fetchTopPodcasts(limit: 10)

    #expect(!podcasts.isEmpty)
    #expect(podcasts.count <= 10)
    let first = try #require(podcasts.first)
    #expect(first.id.value > 0)
    #expect(!first.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    #expect(!first.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }
}
