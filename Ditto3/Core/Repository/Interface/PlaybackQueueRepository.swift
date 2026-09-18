import Entity

public protocol PlaybackQueueRepository: Sendable {
  func fetchQueue() async throws -> [QueueItem]
  func playNext(_ episode: Episode) async throws
  func addToQueue(_ episode: Episode) async throws
  func move(episodeID: EpisodeID, to index: Int) async throws
  func remove(episodeID: EpisodeID) async throws
  func removeAll() async throws
  func changes() async -> AsyncStream<Void>
}
