import Entity
import Foundation
import Platform
import Repository

public actor FollowingRepositoryImp: FollowingRepository {
  private let userDefaults: UserDefaultsProtocol
  private let now: () -> Date
  private let key = "followed-podcasts"

  private var changeContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]

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

  public func fetchFollowedPodcasts() throws -> [FollowedPodcast] {
    load().sorted { $0.followedAt > $1.followedAt }
  }

  public func isFollowing(podcastID: PodcastID) throws -> Bool {
    load().contains { $0.podcast.id == podcastID }
  }

  public func follow(_ podcast: Podcast) throws {
    var podcasts = load()
    guard !podcasts.contains(where: { $0.podcast.id == podcast.id }) else { return }

    podcasts.append(FollowedPodcast(podcast: podcast, followedAt: now()))
    try persist(podcasts)
    notifyChanges()
  }

  public func unfollow(podcastID: PodcastID) throws {
    var podcasts = load()
    let previousCount = podcasts.count
    podcasts.removeAll { $0.podcast.id == podcastID }
    guard podcasts.count != previousCount else { return }

    try persist(podcasts)
    notifyChanges()
  }

  public func changes() -> AsyncStream<Void> {
    let id = UUID()
    var registeredContinuation: AsyncStream<Void>.Continuation?
    let stream = AsyncStream<Void> { continuation in
      registeredContinuation = continuation
    }
    guard let continuation = registeredContinuation else { return stream }

    continuation.onTermination = { [weak self] _ in
      Task {
        await self?.removeChangeContinuation(id: id)
      }
    }
    changeContinuations[id] = continuation
    return stream
  }

  private func load() -> [FollowedPodcast] {
    guard let data = userDefaults.data(forKey: key) else { return [] }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    guard let payload = try? decoder.decode(Payload.self, from: data),
          payload.version == Payload.currentVersion else {
      return []
    }

    return payload.items.map { $0.toDomain() }
  }

  private func persist(_ podcasts: [FollowedPodcast]) throws {
    let payload = Payload(
      version: Payload.currentVersion,
      items: podcasts.map(Payload.Item.init)
    )
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.sortedKeys]
    userDefaults.set(value: try encoder.encode(payload), forKey: key)
  }

  private func notifyChanges() {
    for continuation in changeContinuations.values {
      continuation.yield(())
    }
  }

  private func removeChangeContinuation(id: UUID) {
    changeContinuations[id] = nil
  }
}

private struct Payload: Codable {
  static let currentVersion = 1

  let version: Int
  let items: [Item]

  struct Item: Codable {
    let podcast: PodcastRecord
    let followedAt: Date

    init(_ followedPodcast: FollowedPodcast) {
      self.podcast = PodcastRecord(followedPodcast.podcast)
      self.followedAt = followedPodcast.followedAt
    }

    func toDomain() -> FollowedPodcast {
      FollowedPodcast(podcast: podcast.toDomain(), followedAt: followedAt)
    }
  }

  struct PodcastRecord: Codable {
    let id: Int
    let title: String
    let author: String
    let artworkURL: URL?
    let feedURL: URL?
    let summary: String?

    init(_ podcast: Podcast) {
      self.id = podcast.id.value
      self.title = podcast.title
      self.author = podcast.author
      self.artworkURL = podcast.artworkURL
      self.feedURL = podcast.feedURL
      self.summary = podcast.summary
    }

    func toDomain() -> Podcast {
      Podcast(
        id: PodcastID(id),
        title: title,
        author: author,
        artworkURL: artworkURL,
        feedURL: feedURL,
        summary: summary
      )
    }
  }
}
