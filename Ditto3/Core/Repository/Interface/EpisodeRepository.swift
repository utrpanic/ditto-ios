import Entity
import Foundation

public protocol EpisodeRepository {
  func searchEpisodes(query: String) async throws -> [Episode]

  func fetchEpisodes(
    podcast: Podcast,
    feedURL: URL,
    limit: Int?
  ) async throws -> [Episode]
}
