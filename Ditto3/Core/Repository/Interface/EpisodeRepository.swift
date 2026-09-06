import Entity
import Foundation

public protocol EpisodeRepository {
  func fetchEpisodes(
    podcast: Podcast,
    feedURL: URL,
    limit: Int?
  ) async throws -> [Episode]
}
