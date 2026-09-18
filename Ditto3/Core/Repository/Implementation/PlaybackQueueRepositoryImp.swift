import Entity
import Foundation
import Platform
import Repository

public actor PlaybackQueueRepositoryImp: PlaybackQueueRepository {
  private let userDefaults: UserDefaultsProtocol
  private let now: () -> Date
  private let key = "playback-queue"

  private var changeContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]

  public init(userDefaults: UserDefaultsProtocol) {
    self.userDefaults = userDefaults
    self.now = { Date() }
  }

  init(userDefaults: UserDefaultsProtocol, now: @escaping () -> Date) {
    self.userDefaults = userDefaults
    self.now = now
  }

  public func fetchQueue() throws -> [QueueItem] {
    load()
  }

  public func playNext(_ episode: Episode) throws {
    var queue = load()
    queue.removeAll { $0.episode.id == episode.id }
    queue.insert(QueueItem(episode: episode, enqueuedAt: now()), at: 0)
    try persist(queue)
    notifyChanges()
  }

  public func addToQueue(_ episode: Episode) throws {
    var queue = load()
    queue.removeAll { $0.episode.id == episode.id }
    queue.append(QueueItem(episode: episode, enqueuedAt: now()))
    try persist(queue)
    notifyChanges()
  }

  public func move(episodeID: EpisodeID, to index: Int) throws {
    var queue = load()
    guard let sourceIndex = queue.firstIndex(where: { $0.episode.id == episodeID }) else { return }
    let destinationIndex = min(max(index, 0), queue.count - 1)
    guard sourceIndex != destinationIndex else { return }

    let item = queue.remove(at: sourceIndex)
    queue.insert(item, at: destinationIndex)
    try persist(queue)
    notifyChanges()
  }

  public func remove(episodeID: EpisodeID) throws {
    var queue = load()
    let previousCount = queue.count
    queue.removeAll { $0.episode.id == episodeID }
    guard queue.count != previousCount else { return }

    try persist(queue)
    notifyChanges()
  }

  public func removeAll() throws {
    guard !load().isEmpty else { return }
    try persist([])
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

  private func load() -> [QueueItem] {
    guard let data = userDefaults.data(forKey: key) else { return [] }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    guard let payload = try? decoder.decode(Payload.self, from: data),
          payload.version == Payload.currentVersion else {
      return []
    }

    return payload.items.map { $0.toDomain() }
  }

  private func persist(_ queue: [QueueItem]) throws {
    let payload = Payload(
      version: Payload.currentVersion,
      items: queue.map(Payload.Item.init)
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
    let episode: EpisodeRecord
    let enqueuedAt: Date

    init(_ queueItem: QueueItem) {
      self.episode = EpisodeRecord(queueItem.episode)
      self.enqueuedAt = queueItem.enqueuedAt
    }

    func toDomain() -> QueueItem {
      QueueItem(episode: episode.toDomain(), enqueuedAt: enqueuedAt)
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
