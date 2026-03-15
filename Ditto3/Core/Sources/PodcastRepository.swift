public protocol PodcastRepository {
  func fetchTopPodcasts(limit: Int) async throws -> [Podcast]
  func searchPodcasts(query: String) async throws -> [Podcast]
}
