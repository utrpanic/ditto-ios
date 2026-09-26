import Entity
import Foundation

public protocol PodcastRepository {
  func fetchTopPodcasts(limit: Int) async throws -> [Podcast]
  func searchPodcasts(query: String) async throws -> [Podcast]
  func resolveFeedURL(podcastID: PodcastID) async throws -> URL
}
