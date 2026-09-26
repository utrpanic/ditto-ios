import Entity
import Foundation
import Platform
import Repository

public actor PlaybackSessionRepositoryImp: PlaybackSessionRepository {
  private let userDefaults: UserDefaultsProtocol
  private let key = "playback-session"

  public init(userDefaults: UserDefaultsProtocol) {
    self.userDefaults = userDefaults
  }

  public func loadSession() throws -> PlaybackSession? {
    guard let data = userDefaults.data(forKey: key) else { return nil }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    guard let payload = try? decoder.decode(Payload.self, from: data),
          payload.version == Payload.currentVersion else {
      return nil
    }
    return payload.session.toDomain()
  }

  public func saveSession(_ session: PlaybackSession) throws {
    let payload = Payload(
      version: Payload.currentVersion,
      session: Payload.SessionRecord(session)
    )
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.sortedKeys]
    userDefaults.set(value: try encoder.encode(payload), forKey: key)
  }

  public func clearSession() throws {
    userDefaults.set(value: Optional<Data>.none, forKey: key)
  }
}

private struct Payload: Codable {
  static let currentVersion = 1

  let version: Int
  let session: SessionRecord

  struct SessionRecord: Codable {
    let episode: EpisodeRecord
    let position: TimeInterval
    let updatedAt: Date

    init(_ session: PlaybackSession) {
      self.episode = EpisodeRecord(session.episode)
      self.position = session.position
      self.updatedAt = session.updatedAt
    }

    func toDomain() -> PlaybackSession {
      PlaybackSession(
        episode: episode.toDomain(),
        position: position,
        updatedAt: updatedAt
      )
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
