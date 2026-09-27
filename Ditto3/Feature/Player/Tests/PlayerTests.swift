import Entity
import Foundation
import Playback
import Repository
import RIBsLite
import Testing
import UIKit
@testable import Player

struct PlayerTests {
  @MainActor
  @Test
  func builderConnectsPlayerRIB() throws {
    let listener = Listener()
    let builder = PlayerBuilder(dependency: Dependency())

    let result = builder.build(listener: listener)

    let viewController = try #require(result as? PlayerViewController)
    let interactor = try #require(viewController.interactor as? PlayerInteractor)
    #expect(interactor.listener === listener)
    #expect(interactor.router != nil)
    #expect(listener.visibility == [false])
  }

  @MainActor
  @Test
  func playbackChangesNotifyListenerWithoutAViewController() async {
    let playbackController = PlaybackControllerSpy()
    let interactor = PlayerInteractor(dependency: Dependency(playbackController: playbackController))
    let listener = Listener()
    interactor.listener = listener
    interactor.activate()
    #expect(listener.visibility == [false])
    await waitUntil { playbackController.streamCallCount == 1 }

    for playback in [PlaybackState.playing(makeSession()), .paused(makeSession()), .idle] {
      playbackController.emit(playback)
      await waitUntil { interactor.store.state.playback == playback }
      #expect(interactor.store.state.playback == playback)
    }

    #expect(listener.visibility == [false, true, false])
  }

  @MainActor
  @Test
  func existingPlaybackNotifiesListenerOnActivation() async {
    let playback = PlaybackState.paused(makeSession())
    let playbackController = PlaybackControllerSpy(initialState: playback)
    let interactor = PlayerInteractor(dependency: Dependency(playbackController: playbackController))
    let listener = Listener()
    interactor.listener = listener

    interactor.activate()
    await waitUntil { listener.visibility.last == true }

    #expect(interactor.store.state.playback == playback)
    #expect(listener.visibility == [false, true])
  }

  @MainActor
  @Test
  func visibilityListenerCanSendActionUsingCommittedPlaybackState() async {
    let playbackController = PlaybackControllerSpy()
    let interactor = PlayerInteractor(dependency: Dependency(playbackController: playbackController))
    let listener = Listener()
    let playback = PlaybackState.playing(makeSession())
    var didSendAction = false
    listener.onVisibilityChange = { [weak interactor] isVisible in
      guard isVisible, !didSendAction, let interactor else { return }
      #expect(interactor.store.state.playback == playback)
      didSendAction = true
      interactor.sendAction(.presentExpanded)
    }
    interactor.listener = listener
    interactor.activate()
    await waitUntil { playbackController.streamCallCount == 1 }

    playbackController.emit(playback)
    await waitUntil { didSendAction }

    #expect(didSendAction)
    #expect(interactor.store.state.isExpanded)
    #expect(interactor.store.state.playback == playback)
  }

  @MainActor
  @Test
  func stateSubscriptionDoesNotRetainPlayerViewControllerOrInteractor() {
    var interactor: PlayerInteractor? = PlayerInteractor(dependency: Dependency())
    var viewController: PlayerViewController? = PlayerViewController(interactor: interactor!)
    let store = interactor!.store
    weak let weakViewController = viewController
    weak let weakInteractor = interactor
    store.state.playback = .playing(makeSession())

    viewController = nil
    interactor = nil
    #expect(weakViewController == nil)
    #expect(weakInteractor == nil)
    store.state.playback = .idle
  }

  @MainActor
  @Test
  func controlsForwardToPersistentPlaybackController() async {
    let playbackController = PlaybackControllerSpy(initialState: .paused(makeSession()))
    let interactor = PlayerInteractor(dependency: Dependency(playbackController: playbackController))
    interactor.activate()
    await waitUntil {
      interactor.store.state.playback == playbackController.initialState
    }

    interactor.sendAction(.togglePlayback)
    interactor.sendAction(.skipBackward)
    interactor.sendAction(.skipForward)
    interactor.sendAction(.seek(to: 48))
    await waitUntil { playbackController.seekPositions == [48] }

    #expect(playbackController.playCallCount == 1)
    #expect(playbackController.skipBackwardCallCount == 1)
    #expect(playbackController.skipForwardCallCount == 1)
    #expect(playbackController.seekPositions == [48])
  }

  @MainActor
  @Test
  func expandedPresentationIsPlayerState() async {
    let playbackController = PlaybackControllerSpy(initialState: .playing(makeSession()))
    let interactor = PlayerInteractor(dependency: Dependency(playbackController: playbackController))
    interactor.activate()
    await waitUntil { interactor.store.state.session != nil }

    interactor.sendAction(.presentExpanded)
    #expect(interactor.store.state.isExpanded)

    interactor.sendAction(.dismissExpanded)
    #expect(!interactor.store.state.isExpanded)

    playbackController.emit(.idle)
    await waitUntil { interactor.store.state.playback == .idle }
    interactor.sendAction(.presentExpanded)
    #expect(!interactor.store.state.isExpanded)
  }

  @MainActor
  @Test
  func queueChangesUpdatePlayerState() async {
    let item = makeQueueItem(id: "next")
    let queueRepository = PlaybackQueueRepositorySpy(items: [item])
    let interactor = PlayerInteractor(dependency: Dependency(
      playbackQueueRepository: queueRepository
    ))

    interactor.activate()

    await waitUntil { interactor.store.state.queue == [item] }
    let laterItem = makeQueueItem(id: "later")
    await queueRepository.stubItems([laterItem, item])
    await waitUntil { interactor.store.state.queue == [laterItem, item] }
    #expect(interactor.store.state.queue == [laterItem, item])
  }

  @MainActor
  @Test
  func queueActionsForwardToRepository() async {
    let first = makeQueueItem(id: "first")
    let second = makeQueueItem(id: "second")
    let queueRepository = PlaybackQueueRepositorySpy(items: [first, second])
    let interactor = PlayerInteractor(dependency: Dependency(
      playbackQueueRepository: queueRepository
    ))
    interactor.activate()
    await waitUntil { interactor.store.state.queue == [first, second] }

    interactor.sendAction(.moveQueueItem(first.episode.id, to: 1))
    await waitUntil { await queueRepository.itemIDs() == [second.episode.id, first.episode.id] }

    interactor.sendAction(.removeQueueItem(second.episode.id))
    await waitUntil { await queueRepository.itemIDs() == [first.episode.id] }

    interactor.sendAction(.clearQueue)
    await waitUntil { await queueRepository.itemIDs().isEmpty }
    #expect(interactor.store.state.queue.isEmpty)
  }

  @MainActor
  @Test
  func selectingQueueItemRemovesItAndStartsPlayback() async {
    let item = makeQueueItem(id: "next")
    let playbackController = PlaybackControllerSpy(initialState: .playing(makeSession()))
    let queueRepository = PlaybackQueueRepositorySpy(items: [item])
    let interactor = PlayerInteractor(dependency: Dependency(
      playbackController: playbackController,
      playbackQueueRepository: queueRepository
    ))
    interactor.activate()
    await waitUntil { interactor.store.state.queue == [item] }

    interactor.sendAction(.playQueueItem(item.episode.id))

    await waitUntil { playbackController.playedEpisode == item.episode }
    #expect(await queueRepository.itemIDs().isEmpty)
  }

  @MainActor
  @Test
  func viewingQueueEpisodeNotifiesListenerWithoutChangingQueue() async {
    let item = makeQueueItem(id: "next")
    let queueRepository = PlaybackQueueRepositorySpy(items: [item])
    let interactor = PlayerInteractor(dependency: Dependency(
      playbackQueueRepository: queueRepository
    ))
    let listener = Listener()
    interactor.listener = listener
    interactor.activate()
    await waitUntil { interactor.store.state.queue == [item] }
    interactor.store.state.isExpanded = true

    interactor.sendAction(.viewQueueEpisode(item.episode.id))

    #expect(listener.requestedEpisode == item.episode)
    #expect(!interactor.store.state.isExpanded)
    #expect(await queueRepository.itemIDs() == [item.episode.id])
  }

  @MainActor
  @Test
  func routerDoesNotRetainViewController() {
    var viewController: UIViewController? = UIViewController()
    weak let weakViewController = viewController
    let router = Router<ViewControllable>(viewController: viewController!)
    #expect(router.viewController?.ui === viewController)

    viewController = nil

    #expect(weakViewController == nil)
    #expect(router.viewController == nil)
  }

  @MainActor
  @Test
  func releasingInteractorEndsPlaybackAndQueueObservations() async {
    let playbackController = PlaybackControllerSpy()
    let queueRepository = PlaybackQueueRepositorySpy()
    var interactor: PlayerInteractor? = PlayerInteractor(dependency: Dependency(
      playbackController: playbackController,
      playbackQueueRepository: queueRepository
    ))
    weak let weakInteractor = interactor
    interactor?.activate()
    await waitUntil {
      let queueCounts = await queueRepository.observationCounts()
      return playbackController.streamCallCount == 1
        && playbackController.completionStreamCallCount == 1
        && queueCounts.started == 1
    }

    interactor = nil

    await waitUntil {
      let queueCounts = await queueRepository.observationCounts()
      return playbackController.stateStreamTerminationCount == 1
        && playbackController.completionStreamTerminationCount == 1
        && queueCounts.terminated == 1
    }
    #expect(weakInteractor == nil)
  }

  @MainActor
  @Test
  func playbackCompletionDequeuesAndPlaysNextEpisode() async {
    let next = makeQueueItem(id: "next")
    let later = makeQueueItem(id: "later")
    let playbackController = PlaybackControllerSpy(initialState: .playing(makeSession()))
    let queueRepository = PlaybackQueueRepositorySpy(items: [next, later])
    let interactor = PlayerInteractor(dependency: Dependency(
      playbackController: playbackController,
      playbackQueueRepository: queueRepository
    ))
    interactor.activate()
    await waitUntil { playbackController.completionStreamCallCount == 1 }

    playbackController.emitCompletion(makeSession())

    await waitUntil { playbackController.playedEpisode == next.episode }
    #expect(await queueRepository.itemIDs() == [later.episode.id])
  }

  @MainActor
  @Test
  func playbackCompletionWithEmptyQueueLeavesPlaybackIdle() async {
    let playbackController = PlaybackControllerSpy(initialState: .playing(makeSession()))
    let queueRepository = PlaybackQueueRepositorySpy()
    let interactor = PlayerInteractor(dependency: Dependency(
      playbackController: playbackController,
      playbackQueueRepository: queueRepository
    ))
    interactor.activate()
    await waitUntil { playbackController.completionStreamCallCount == 1 }

    playbackController.emitCompletion(makeSession())
    await waitUntil { await queueRepository.dequeueCalls() == 1 }

    #expect(playbackController.playedEpisode == nil)
  }

  @MainActor
  @Test
  func persistedSessionRestoresPausedPlayerBeforeObservation() async {
    let session = makeSession()
    let playbackController = PlaybackControllerSpy()
    let sessionRepository = PlaybackSessionRepositorySpy(session: session)
    let interactor = PlayerInteractor(dependency: Dependency(
      playbackController: playbackController,
      playbackSessionRepository: sessionRepository
    ))

    interactor.activate()

    await waitUntil { playbackController.restoredSession == session }
    await waitUntil { interactor.store.state.playback == .paused(session) }
    #expect(interactor.store.state.session == session)
  }

  @MainActor
  @Test
  func playbackProgressIsPersistedAtLimitedIntervalsAndPauseIsImmediate() async {
    let initialSession = makeSession()
    let playbackController = PlaybackControllerSpy(initialState: .playing(initialSession))
    let sessionRepository = PlaybackSessionRepositorySpy()
    let interactor = PlayerInteractor(dependency: Dependency(
      playbackController: playbackController,
      playbackSessionRepository: sessionRepository
    ))
    interactor.activate()
    await waitUntil { await sessionRepository.savedSessions().count == 1 }

    let nearbySession = PlaybackSession(
      episode: initialSession.episode,
      position: initialSession.position + 2,
      updatedAt: initialSession.updatedAt
    )
    playbackController.emit(.playing(nearbySession))
    await Task.yield()
    #expect(await sessionRepository.savedSessions().count == 1)

    let laterSession = PlaybackSession(
      episode: initialSession.episode,
      position: initialSession.position + 5,
      updatedAt: initialSession.updatedAt
    )
    playbackController.emit(.playing(laterSession))
    await waitUntil { await sessionRepository.savedSessions().count == 2 }
    #expect(await sessionRepository.savedSessions().count == 2)

    playbackController.emit(.paused(nearbySession))
    await waitUntil { await sessionRepository.savedSessions().count == 3 }
    #expect(await sessionRepository.savedSessions().count == 3)
    #expect(await sessionRepository.savedSessions().last == nearbySession)
  }

  @MainActor
  @Test
  func idlePlaybackClearsPersistedSession() async {
    let playbackController = PlaybackControllerSpy(initialState: .playing(makeSession()))
    let sessionRepository = PlaybackSessionRepositorySpy()
    let interactor = PlayerInteractor(dependency: Dependency(
      playbackController: playbackController,
      playbackSessionRepository: sessionRepository
    ))
    interactor.activate()
    await waitUntil { await sessionRepository.savedSessions().count == 1 }

    playbackController.emit(.idle)

    await waitUntil { await sessionRepository.clearCallCount() == 1 }
    #expect(await sessionRepository.currentSession() == nil)
  }

  @MainActor
  @Test
  func queueMutationFailureKeepsSnapshotAndPublishesMessage() async {
    let item = makeQueueItem(id: "next")
    let queueRepository = PlaybackQueueRepositorySpy(items: [item], failsMutations: true)
    let interactor = PlayerInteractor(dependency: Dependency(
      playbackQueueRepository: queueRepository
    ))
    interactor.activate()
    await waitUntil { interactor.store.state.queue == [item] }

    interactor.sendAction(.removeQueueItem(item.episode.id))

    await waitUntil { interactor.store.state.queueFailureMessage != nil }
    #expect(interactor.store.state.queue == [item])
    #expect(await queueRepository.itemIDs() == [item.episode.id])
  }
}

private func makeSession() -> PlaybackSession {
  PlaybackSession(
    episode: Episode(
      id: EpisodeID("episode-id"),
      podcastTitle: "Architecture Talks",
      title: "Persistent Player",
      feedURL: URL(string: "https://example.com/feed.xml")!,
      audioURL: URL(string: "https://example.com/audio.mp3"),
      duration: 120
    ),
    position: 30,
    updatedAt: Date(timeIntervalSince1970: 1_000)
  )
}

private func makeQueueItem(id: String) -> QueueItem {
  QueueItem(
    episode: Episode(
      id: EpisodeID(id),
      podcastTitle: "Architecture Talks",
      title: "Queue \(id)",
      feedURL: URL(string: "https://example.com/feed.xml")!,
      audioURL: URL(string: "https://example.com/\(id).mp3")
    ),
    enqueuedAt: Date(timeIntervalSince1970: 1_000)
  )
}

@MainActor
private func waitUntil(_ condition: () async -> Bool) async {
  for _ in 0..<1_000 {
    guard !(await condition()) else { return }
    await Task.yield()
  }
}

@MainActor
private struct Dependency: PlayerDependency {
  let playbackController: PlaybackControlling
  let playbackQueueRepository: PlaybackQueueRepository
  let playbackSessionRepository: PlaybackSessionRepository

  init(
    playbackController: PlaybackControlling? = nil,
    playbackQueueRepository: PlaybackQueueRepository? = nil,
    playbackSessionRepository: PlaybackSessionRepository? = nil
  ) {
    self.playbackController = playbackController ?? PlaybackControllerSpy()
    self.playbackQueueRepository = playbackQueueRepository ?? PlaybackQueueRepositorySpy()
    self.playbackSessionRepository = playbackSessionRepository ?? PlaybackSessionRepositorySpy()
  }
}

@MainActor
private final class PlaybackControllerSpy: PlaybackControlling {
  let initialState: PlaybackState
  private var currentState: PlaybackState
  private var continuations: [AsyncStream<PlaybackState>.Continuation] = []
  private var completionContinuations: [AsyncStream<PlaybackSession>.Continuation] = []
  private(set) var playCallCount = 0
  private(set) var pauseCallCount = 0
  private(set) var skipBackwardCallCount = 0
  private(set) var skipForwardCallCount = 0
  private(set) var seekPositions: [TimeInterval] = []
  private(set) var streamCallCount = 0
  private(set) var completionStreamCallCount = 0
  private(set) var stateStreamTerminationCount = 0
  private(set) var completionStreamTerminationCount = 0
  private(set) var playedEpisode: Episode?
  private(set) var restoredSession: PlaybackSession?

  init(initialState: PlaybackState = .idle) {
    self.initialState = initialState
    self.currentState = initialState
  }

  func play(_ episode: Episode) async {
    playedEpisode = episode
  }

  func restore(_ session: PlaybackSession) async {
    restoredSession = session
    currentState = .paused(session)
    emit(currentState)
  }

  func play() async {
    playCallCount += 1
  }

  func pause() {
    pauseCallCount += 1
  }

  func seek(to position: TimeInterval) async {
    seekPositions.append(position)
  }

  func skipBackward() {
    skipBackwardCallCount += 1
  }

  func skipForward() {
    skipForwardCallCount += 1
  }

  func stateChanges() -> AsyncStream<PlaybackState> {
    streamCallCount += 1
    let (stream, continuation) = AsyncStream<PlaybackState>.makeStream()
    continuation.onTermination = { [weak self] _ in
      Task { @MainActor in
        self?.stateStreamTerminationCount += 1
      }
    }
    continuation.yield(currentState)
    continuations.append(continuation)
    return stream
  }

  func completionEvents() -> AsyncStream<PlaybackSession> {
    completionStreamCallCount += 1
    return AsyncStream { continuation in
      continuation.onTermination = { [weak self] _ in
        Task { @MainActor in
          self?.completionStreamTerminationCount += 1
        }
      }
      completionContinuations.append(continuation)
    }
  }

  func emit(_ state: PlaybackState) {
    currentState = state
    for continuation in continuations {
      continuation.yield(state)
    }
  }

  func emitCompletion(_ session: PlaybackSession) {
    for continuation in completionContinuations {
      continuation.yield(session)
    }
  }
}

private actor PlaybackSessionRepositorySpy: PlaybackSessionRepository {
  private var session: PlaybackSession?
  private var saved: [PlaybackSession] = []
  private var clearCalls = 0

  init(session: PlaybackSession? = nil) {
    self.session = session
  }

  func loadSession() -> PlaybackSession? {
    session
  }

  func saveSession(_ session: PlaybackSession) {
    self.session = session
    saved.append(session)
  }

  func clearSession() {
    session = nil
    clearCalls += 1
  }

  func savedSessions() -> [PlaybackSession] {
    saved
  }

  func currentSession() -> PlaybackSession? {
    session
  }

  func clearCallCount() -> Int {
    clearCalls
  }
}

private actor PlaybackQueueRepositorySpy: PlaybackQueueRepository {
  private enum MutationError: Error {
    case failed
  }

  private var items: [QueueItem]
  private var dequeueCallCount = 0
  private let failsMutations: Bool
  private var continuations: [AsyncStream<Void>.Continuation] = []
  private var startedObservationCount = 0
  private var terminatedObservationCount = 0

  init(items: [QueueItem] = [], failsMutations: Bool = false) {
    self.items = items
    self.failsMutations = failsMutations
  }

  func fetchQueue() -> [QueueItem] { items }

  func dequeue() throws -> QueueItem? {
    dequeueCallCount += 1
    if failsMutations { throw MutationError.failed }
    guard !items.isEmpty else { return nil }
    let item = items.removeFirst()
    emitChange()
    return item
  }

  func playNext(_ episode: Episode) throws {
    if failsMutations { throw MutationError.failed }
    items.removeAll { $0.episode.id == episode.id }
    items.insert(QueueItem(episode: episode, enqueuedAt: Date()), at: 0)
    emitChange()
  }

  func addToQueue(_ episode: Episode) throws {
    if failsMutations { throw MutationError.failed }
    items.removeAll { $0.episode.id == episode.id }
    items.append(QueueItem(episode: episode, enqueuedAt: Date()))
    emitChange()
  }

  func move(episodeID: EpisodeID, to index: Int) throws {
    if failsMutations { throw MutationError.failed }
    guard let sourceIndex = items.firstIndex(where: { $0.episode.id == episodeID }) else { return }
    let item = items.remove(at: sourceIndex)
    items.insert(item, at: min(max(index, 0), items.count))
    emitChange()
  }

  func remove(episodeID: EpisodeID) throws {
    if failsMutations { throw MutationError.failed }
    items.removeAll { $0.episode.id == episodeID }
    emitChange()
  }

  func removeAll() throws {
    if failsMutations { throw MutationError.failed }
    items = []
    emitChange()
  }

  func changes() -> AsyncStream<Void> {
    startedObservationCount += 1
    return AsyncStream<Void> { continuation in
      continuation.onTermination = { [weak self] _ in
        Task {
          await self?.terminateObservation()
        }
      }
      continuations.append(continuation)
    }
  }

  func observationCounts() -> (started: Int, terminated: Int) {
    (startedObservationCount, terminatedObservationCount)
  }

  func stubItems(_ items: [QueueItem]) {
    self.items = items
    emitChange()
  }

  func itemIDs() -> [EpisodeID] {
    items.map(\.episode.id)
  }

  func dequeueCalls() -> Int {
    dequeueCallCount
  }

  private func emitChange() {
    for continuation in continuations {
      continuation.yield(())
    }
  }

  private func terminateObservation() {
    terminatedObservationCount += 1
  }
}

@MainActor
private final class Listener: PlayerListener {
  private(set) var requestedEpisode: Episode?
  private(set) var visibility: [Bool] = []
  var onVisibilityChange: ((Bool) -> Void)?

  func playerDidRequestEpisode(_ episode: Episode) {
    requestedEpisode = episode
  }

  func playerVisibilityDidChange(_ isVisible: Bool) {
    visibility.append(isVisible)
    onVisibilityChange?(isVisible)
  }
}
