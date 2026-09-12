import Entity
import Foundation
import Platform
import Repository

public actor KeepRepositoryImp: KeepRepository {
  private let userDefaults: UserDefaultsProtocol
  private let now: () -> Date
  private let key = "kept-episodes"

  public init(userDefaults: UserDefaultsProtocol) {
    self.userDefaults = userDefaults
    self.now = { Date() }
  }

  init(
    userDefaults: UserDefaultsProtocol,
    now: @escaping () -> Date
  ) {
    self.userDefaults = userDefaults
    self.now = now
  }

  public func fetchKeptEpisodes() throws -> [KeptEpisode] {
    load().sorted { $0.keptAt > $1.keptAt }
  }

  public func isKept(episodeID: EpisodeID) throws -> Bool {
    load().contains { $0.episode.id == episodeID }
  }

  public func keep(_ episode: Episode) throws {
    var episodes = load()
    guard !episodes.contains(where: { $0.episode.id == episode.id }) else { return }

    episodes.append(KeptEpisode(episode: episode, keptAt: now()))
    try persist(episodes)
  }

  public func unkeep(episodeID: EpisodeID) throws {
    var episodes = load()
    let previousCount = episodes.count
    episodes.removeAll { $0.episode.id == episodeID }
    guard episodes.count != previousCount else { return }

    try persist(episodes)
  }

  private func load() -> [KeptEpisode] {
    guard let data = userDefaults.data(forKey: key) else { return [] }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    guard let payload = try? decoder.decode(Payload.self, from: data),
          payload.version == Payload.currentVersion else {
      return []
    }

    return payload.items.map { $0.toDomain() }
  }

  private func persist(_ episodes: [KeptEpisode]) throws {
    let payload = Payload(
      version: Payload.currentVersion,
      items: episodes.map(Payload.Item.init)
    )
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.sortedKeys]
    userDefaults.set(value: try encoder.encode(payload), forKey: key)
  }
}

private struct Payload: Codable {
  static let currentVersion = 1

  let version: Int
  let items: [Item]

  struct Item: Codable {
    let episode: EpisodeRecord
    let keptAt: Date

    init(_ keptEpisode: KeptEpisode) {
      self.episode = EpisodeRecord(keptEpisode.episode)
      self.keptAt = keptEpisode.keptAt
    }

    func toDomain() -> KeptEpisode {
      KeptEpisode(episode: episode.toDomain(), keptAt: keptAt)
    }
  }

  struct EpisodeRecord: Codable {
    let id: String
    let podcastID: Int?
    let podcastTitle: String
    let title: String
    let author: String?
    let artworkURL: URL?
    let audioURL: URL?
    let pageURL: URL?
    let description: String?
    let publishedAt: Date?
    let duration: TimeInterval?
    let feedURL: URL

    init(_ episode: Episode) {
      self.id = episode.id.value
      self.podcastID = episode.podcastID?.value
      self.podcastTitle = episode.podcastTitle
      self.title = episode.title
      self.author = episode.author
      self.artworkURL = episode.artworkURL
      self.audioURL = episode.audioURL
      self.pageURL = episode.pageURL
      self.description = episode.description
      self.publishedAt = episode.publishedAt
      self.duration = episode.duration
      self.feedURL = episode.feedURL
    }

    func toDomain() -> Episode {
      Episode(
        id: EpisodeID(id),
        podcastID: podcastID.map(PodcastID.init),
        podcastTitle: podcastTitle,
        title: title,
        feedURL: feedURL,
        author: author,
        artworkURL: artworkURL,
        audioURL: audioURL,
        pageURL: pageURL,
        description: description,
        publishedAt: publishedAt,
        duration: duration
      )
    }
  }
}
