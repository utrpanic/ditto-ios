import Entity

public protocol KeepRepository {
  func fetchKeptEpisodes() async throws -> [KeptEpisode]
  func isKept(episodeID: EpisodeID) async throws -> Bool
  func keep(_ episode: Episode) async throws
  func unkeep(episodeID: EpisodeID) async throws
}
