import Foundation
import Platform

public final class PodcastRepositoryImp: PodcastRepository, @unchecked Sendable {
  private let session: URLSessionProtocol

  public init(session: URLSessionProtocol) {
    self.session = session
  }

  public func searchPodcasts(query: String) async throws -> [Podcast] {
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuery.isEmpty else { return [] }

    var components = URLComponents(string: "https://itunes.apple.com/search")
    components?.queryItems = [
      .init(name: "term", value: trimmedQuery),
      .init(name: "media", value: "podcast"),
      .init(name: "entity", value: "podcast"),
      .init(name: "limit", value: "50"),
    ]

    guard let url = components?.url else {
      throw PodcastRepositoryImpError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let (data, response) = try await session.data(for: request)
    try validate(response: response)

    let payload = try JSONDecoder().decode(SearchResponse.self, from: data)
    return payload.results.compactMap { $0.toDomain() }
  }

  public func fetchTopPodcasts(limit: Int) async throws -> [Podcast] {
    let clampedLimit = min(max(limit, 1), 100)
    guard let url = URL(
      string: "https://rss.applemarketingtools.com/api/v2/us/podcasts/top/\(clampedLimit)/podcasts.json"
    ) else {
      throw PodcastRepositoryImpError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let (data, response) = try await session.data(for: request)
    try validate(response: response)

    let payload = try JSONDecoder().decode(TopPodcastsResponse.self, from: data)
    return payload.feed.results.compactMap { $0.toDomain() }
  }

  private func validate(response: URLResponse) throws {
    guard let httpResponse = response as? HTTPURLResponse else { return }
    guard (200 ..< 300).contains(httpResponse.statusCode) else {
      throw PodcastRepositoryImpError.httpStatus(httpResponse.statusCode)
    }
  }
}

enum PodcastRepositoryImpError: Error {
  case invalidURL
  case httpStatus(Int)
}

private struct SearchResponse: Decodable {
  let results: [SearchResult]
}

private struct SearchResult: Decodable {
  let collectionId: Int?
  let collectionName: String?
  let artistName: String?
  let artworkUrl600: URL?
  let artworkUrl100: URL?
  let feedUrl: URL?
  let description: String?

  func toDomain() -> Podcast? {
    guard let collectionId, let collectionName, let artistName else { return nil }
    return Podcast(
      id: PodcastID(collectionId),
      title: collectionName,
      author: artistName,
      artworkURL: artworkUrl600 ?? artworkUrl100,
      feedURL: feedUrl,
      summary: description
    )
  }
}

private struct TopPodcastsResponse: Decodable {
  let feed: Feed

  struct Feed: Decodable {
    let results: [Result]
  }

  struct Result: Decodable {
    let id: String
    let name: String
    let artistName: String
    let artworkUrl100: URL?
    let artworkUrl60: URL?

    func toDomain() -> Podcast? {
      guard let intID = Int(id) else { return nil }
      return Podcast(
        id: PodcastID(intID),
        title: name,
        author: artistName,
        artworkURL: artworkUrl100 ?? artworkUrl60,
        feedURL: nil,
        summary: nil
      )
    }
  }
}
