import Foundation

public struct PodcastID: Hashable, Sendable {
  public let value: Int
  public init(_ value: Int) {
    self.value = value
  }
}

public struct Podcast: Equatable, Sendable, Identifiable {
  public let id: PodcastID
  public let title: String
  public let author: String
  public let artworkURL: URL?
  public let feedURL: URL?
  public let summary: String?

  public init(
    id: PodcastID,
    title: String,
    author: String,
    artworkURL: URL? = nil,
    feedURL: URL? = nil,
    summary: String? = nil
  ) {
    self.id = id
    self.title = title
    self.author = author
    self.artworkURL = artworkURL
    self.feedURL = feedURL
    self.summary = summary
  }
}
