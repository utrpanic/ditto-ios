import Entity
import Foundation
import Platform
import Repository

public final class EpisodeRepositoryImp: EpisodeRepository {
  private let session: URLSessionProtocol

  public init(session: URLSessionProtocol) {
    self.session = session
  }

  public func fetchEpisodes(
    podcast: Podcast,
    feedURL: URL,
    limit: Int?
  ) async throws -> [Episode] {
    if let limit, limit <= 0 { return [] }

    var request = URLRequest(url: feedURL)
    request.httpMethod = "GET"

    let (data, response) = try await session.data(for: request)
    if let httpResponse = response as? HTTPURLResponse,
       !(200 ..< 300).contains(httpResponse.statusCode) {
      throw EpisodeRepositoryImpError.httpStatus(httpResponse.statusCode)
    }

    let episodes = try PodcastRSSParser(
      podcast: podcast,
      feedURL: feedURL
    ).parse(data: data)

    guard let limit else { return episodes }
    return Array(episodes.prefix(limit))
  }
}

enum EpisodeRepositoryImpError: Error {
  case httpStatus(Int)
  case invalidFeed
}

private final class PodcastRSSParser: NSObject, XMLParserDelegate {
  private struct Item {
    var title = ""
    var guid = ""
    var author = ""
    var description = ""
    var link = ""
    var publishedAt = ""
    var duration = ""
    var artworkURL: URL?
    var audioURL: URL?
  }

  private let podcast: Podcast
  private let feedURL: URL
  private var item: Item?
  private var text = ""
  private var episodes: [Episode] = []

  init(podcast: Podcast, feedURL: URL) {
    self.podcast = podcast
    self.feedURL = feedURL
  }

  func parse(data: Data) throws -> [Episode] {
    let parser = XMLParser(data: data)
    parser.delegate = self
    parser.shouldResolveExternalEntities = false

    guard parser.parse() else {
      throw parser.parserError ?? EpisodeRepositoryImpError.invalidFeed
    }

    return episodes.enumerated()
      .sorted { lhs, rhs in
        let lhsDate = lhs.element.publishedAt ?? .distantPast
        let rhsDate = rhs.element.publishedAt ?? .distantPast
        return lhsDate == rhsDate ? lhs.offset < rhs.offset : lhsDate > rhsDate
      }
      .map(\.element)
  }

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String] = [:]
  ) {
    let element = normalized(qName ?? elementName)
    text = ""

    if element == "item" {
      item = Item()
    } else if element == "enclosure", item != nil {
      item?.audioURL = attributeDict["url"].flatMap(URL.init(string:))
    } else if element == "image", item != nil {
      item?.artworkURL = attributeDict["href"].flatMap(URL.init(string:))
    }
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    text += string
  }

  func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
    text += String(decoding: CDATABlock, as: UTF8.self)
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    let element = normalized(qName ?? elementName)
    let value = text.trimmingCharacters(in: .whitespacesAndNewlines)

    if item != nil {
      switch element {
      case "title": item?.title += value
      case "guid": item?.guid += value
      case "author": item?.author += value
      case "description", "encoded":
        if item?.description.isEmpty == true { item?.description = value }
      case "link": item?.link += value
      case "pubdate", "published": item?.publishedAt += value
      case "duration": item?.duration += value
      case "item":
        if let item, let episode = makeEpisode(item) {
          episodes.append(episode)
        }
        item = nil
      default: break
      }
    }

    text = ""
  }

  private func makeEpisode(_ item: Item) -> Episode? {
    let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !title.isEmpty else { return nil }

    let publishedAt = parseDate(item.publishedAt)
    let idValue = firstNonempty(item.guid, item.audioURL?.absoluteString, item.link)
      ?? [feedURL.absoluteString, title, item.publishedAt].joined(separator: "|")

    return Episode(
      id: EpisodeID(idValue),
      podcastID: podcast.id,
      podcastTitle: podcast.title,
      title: title,
      feedURL: feedURL,
      author: firstNonempty(item.author, podcast.author),
      artworkURL: item.artworkURL ?? podcast.artworkURL,
      audioURL: item.audioURL,
      pageURL: URL(string: item.link),
      description: plainText(item.description),
      publishedAt: publishedAt,
      duration: parseDuration(item.duration)
    )
  }

  private func normalized(_ element: String) -> String {
    element.split(separator: ":").last.map(String.init)?.lowercased() ?? element.lowercased()
  }

  private func firstNonempty(_ values: String?...) -> String? {
    values
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .first(where: { !$0.isEmpty })
  }

  private func parseDate(_ value: String) -> Date? {
    let formats = [
      "EEE, dd MMM yyyy HH:mm:ss Z",
      "EEE, d MMM yyyy HH:mm:ss Z",
      "dd MMM yyyy HH:mm:ss Z",
      "yyyy-MM-dd'T'HH:mm:ssZ",
    ]

    for format in formats {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.timeZone = TimeZone(secondsFromGMT: 0)
      formatter.dateFormat = format
      if let date = formatter.date(from: value) { return date }
    }
    return nil
  }

  private func parseDuration(_ value: String) -> TimeInterval? {
    let components = value.split(separator: ":").compactMap { Double($0) }
    guard !components.isEmpty else { return nil }

    return components.reversed().enumerated().reduce(0) { result, entry in
      result + entry.element * pow(60, Double(entry.offset))
    }
  }

  private func plainText(_ value: String) -> String? {
    let withoutTags = value.replacingOccurrences(
      of: "<[^>]+>",
      with: " ",
      options: .regularExpression
    )
    let normalized = withoutTags
      .components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .joined(separator: " ")
    return normalized.isEmpty ? nil : normalized
  }
}
