import Foundation

public struct EpisodeID: Hashable, Sendable {
  public let value: String

  public init(_ value: String) {
    self.value = value
  }
}

public struct Episode: Equatable, Sendable, Identifiable {
  public let id: EpisodeID
  public let podcastID: PodcastID?
  public let podcastTitle: String
  public let title: String
  public let author: String?
  public let artworkURL: URL?
  public let audioURL: URL?
  public let pageURL: URL?
  public let description: String?
  public let publishedAt: Date?
  public let duration: TimeInterval?
  public let feedURL: URL

  public init(
    id: EpisodeID,
    podcastID: PodcastID? = nil,
    podcastTitle: String,
    title: String,
    feedURL: URL,
    author: String? = nil,
    artworkURL: URL? = nil,
    audioURL: URL? = nil,
    pageURL: URL? = nil,
    description: String? = nil,
    publishedAt: Date? = nil,
    duration: TimeInterval? = nil
  ) {
    self.id = id
    self.podcastID = podcastID
    self.podcastTitle = podcastTitle
    self.title = title
    self.author = author
    self.artworkURL = artworkURL
    self.audioURL = audioURL
    self.pageURL = pageURL
    self.description = description
    self.publishedAt = publishedAt
    self.duration = duration
    self.feedURL = feedURL
  }
}
