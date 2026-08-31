# TRD: KeepCast

## 1. Technical Summary

KeepCast는 비로그인 사용자가 인기 podcast episode를 탐색하고, 관심 있는 episode를 local keep list에 저장한 뒤 streaming playback할 수 있는 iOS app이다.

MVP의 핵심 기술 목표는 podcast 중심의 public data source를 episode 중심 product surface로 변환하는 것이다. 이를 위해 Apple RSS Marketing Tools API, iTunes Search/Lookup API, public Podcast RSS feed를 조합하고, feature module은 repository interface만 의존하도록 구성한다.

초기 구현은 다음 루프를 지원한다.

```text
Explore -> Episode Detail -> Keep/Unkeep -> Playback -> Keep List
```

## 2. Scope

### In Scope

- 인기 podcast 후보 조회
- podcast feed URL discovery
- RSS feed parsing
- episode list normalization
- episode keep/unkeep
- local keep persistence
- episode streaming playback
- loading, empty, error state
- keyword search

### Out of Scope

- 로그인
- 서버 백엔드
- cross-device sync
- paid/private RSS feed
- offline download
- personalized recommendation
- creator/podcaster tools
- production analytics integration

## 3. Architecture

### Module Boundaries

```text
Feature
  Explore
  Episode
  Keeps
  Player

Core
  Entity
  Repository/Interface
  Repository/Implementation

Platform
  URLSessionProtocol
  LocalPersistence
  AudioPlayback
  Analytics
```

### Dependency Direction

```text
Feature -> Repository Interface -> Repository Implementation -> Platform
Feature -> Entity
Repository -> Entity
Repository Implementation -> URLSessionProtocol / LocalPersistence
Player Feature -> Playback Interface -> AVPlayer-backed Implementation
```

Feature modules must not depend on concrete repository implementations. Composition remains app-level through dependency injection.

## 4. Proposed Feature Modules

### Explore

Primary entry point. Displays episode-first feed.

Responsibilities:

- Load ranked episode candidates
- Render episode rows
- Support keep/unkeep quick action
- Navigate to episode detail
- Start playback when audio URL is available

Suggested files:

```text
Feature/Explore/Sources/ExploreBuildable.swift
Feature/Explore/Sources/ExploreBuilder.swift
Feature/Explore/Sources/ExploreInteractor.swift
Feature/Explore/Sources/ExploreRouter.swift
Feature/Explore/Sources/ExploreViewController.swift
Feature/Explore/Sources/ExploreView.swift
Feature/Explore/Sources/ExploreState.swift
```

### Episode

Displays metadata for a selected episode.

Responsibilities:

- Episode title, artwork, podcast title, description, duration, publish date
- Support keep/unkeep
- Support playback

### Keeps

Displays locally kept episodes.

Responsibilities:

- Load kept episodes from local persistence
- Sort by `keptAt` descending
- Support unkeep
- Support playback

### Player

Owns playback state and control surface.

Responsibilities:

- Start streaming from `audioURL`
- Publish playback state
- Pause/resume
- Report playback failures

For MVP, a shared player service can be injected into Explore, Episode, and Keeps instead of building a full standalone RIB.

## 5. Core Entities

도메인 관계는 `Podcast 1 -> N Episode`로 정의한다. 기존 `Podcast`와 `PodcastID`를 그대로 사용하고, 새로 추가하는 `Episode`는 `podcastID`로 소속 podcast를 참조한다.

```swift
public struct PodcastID: Hashable, Sendable {
  public let value: Int
}

public struct Podcast: Equatable, Sendable, Identifiable {
  public let id: PodcastID
  public let title: String
  public let author: String
  public let artworkURL: URL?
  public let feedURL: URL?
  public let summary: String?
}

public struct EpisodeID: Hashable, Sendable {
  public let value: String
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
}

public struct KeptEpisode: Equatable, Sendable {
  public let episode: Episode
  public let keptAt: Date
}
```

### Episode Identity Rule

Use the first available stable identifier:

1. RSS item `guid`
2. RSS item `enclosure.url`
3. hash of `feedURL + title + publishedAt`

The resulting `EpisodeID.value` should be a string because RSS GUIDs are not guaranteed to be numeric.

## 6. Repository Interfaces

### EpisodeRepository

```swift
public protocol EpisodeRepository {
  func fetchTrendingEpisodes(limit: Int) async throws -> [Episode]
  func fetchEpisodes(feedURL: URL, limit: Int?) async throws -> [Episode]
}
```

### PodcastFeedRepository

```swift
public protocol PodcastFeedRepository {
  func fetchTopPodcasts(limit: Int, region: String) async throws -> [Podcast]
  func resolveFeedURL(podcastID: PodcastID) async throws -> URL
}
```

### KeepRepository

```swift
public protocol KeepRepository {
  func fetchKeptEpisodes() async throws -> [KeptEpisode]
  func isKept(episodeID: EpisodeID) async throws -> Bool
  func keep(_ episode: Episode) async throws
  func unkeep(episodeID: EpisodeID) async throws
}
```

### PlaybackControlling

```swift
public enum PlaybackState: Equatable {
  case idle
  case loading(EpisodeID)
  case playing(EpisodeID)
  case paused(EpisodeID)
  case failed(EpisodeID, String)
}

public protocol PlaybackControlling: AnyObject {
  var state: AnyPublisher<PlaybackState, Never> { get }
  func play(_ episode: Episode)
  func pause()
  func resume()
  func stop()
}
```

## 7. Data Flow

### Explore Load

```text
ExploreInteractor.didBecomeActive
-> EpisodeRepository.fetchTrendingEpisodes(limit: 30)
-> PodcastFeedRepository.fetchTopPodcasts(limit: N, region: "us")
-> resolve feed URLs via iTunes Lookup/Search
-> fetch RSS feeds
-> parse RSS items into Episode
-> rank/trim normalized episodes
-> merge keep state
-> publish ExploreState.loaded
```

### Keep

```text
User taps keep
-> ExploreInteractor.sendAction(.toggleKeep(episode))
-> KeepRepository.keep(episode)
-> local state updates optimistically
-> analytics event episode_kept
```

### Playback

```text
User taps play
-> PlaybackControlling.play(episode)
-> validate audioURL exists
-> AVPlayerItem(url: audioURL)
-> publish loading
-> publish playing when playback starts
-> publish failed on player error
```

## 8. Data Source Strategy

### Apple RSS Marketing Tools API

Used for top podcast discovery.

Example:

```text
https://rss.applemarketingtools.com/api/v2/us/podcasts/top/{limit}/podcasts.json
```

Limitation: this source is podcast-centric, not episode-centric.

### iTunes Search / Lookup API

Used to resolve `feedUrl` for a podcast.

Expected lookup strategy:

```text
https://itunes.apple.com/lookup?id={collectionId}
```

Required fields:

- `collectionId`
- `collectionName`
- `artistName`
- `artworkUrl600` or `artworkUrl100`
- `feedUrl`

### Public Podcast RSS Feed

Used for episode data.

Required item fields:

- `title`
- `guid`
- `description` or `itunes:summary`
- `pubDate`
- `itunes:duration`
- `enclosure.url`
- `enclosure.type`

## 9. RSS Parsing

Implement RSS parsing as a Core repository implementation detail.

Recommended approach:

- Use `XMLParser` with a dedicated parser object.
- Support common namespaces: `itunes`, `content`, standard RSS fields.
- Parse incrementally off the main thread.
- Normalize HTML descriptions into readable plain text.
- Skip malformed items instead of failing the whole feed.

Parsing rules:

- Accept `audio/*` enclosure types.
- If enclosure type is missing but URL extension is likely audio, keep the episode.
- If title or audio URL is missing, exclude the episode from playable explore results.
- If duration parse fails, set `duration = nil`.
- If publish date parse fails, set `publishedAt = nil`.

## 10. Local Persistence

MVP should use local persistence only.

Recommended implementation:

- Store kept episodes as JSON using an injected local storage abstraction.
- Keep writes atomic.
- Preserve full episode snapshot so Keep list works even if remote feed later changes.
- Sort by `keptAt` descending.

Storage shape:

```json
{
  "version": 1,
  "items": [
    {
      "episode": {},
      "keptAt": "2026-04-26T00:00:00Z"
    }
  ]
}
```

Migration rule:

- If version is missing or unsupported, fail gracefully and return empty keep list.
- Do not crash on corrupted local data.

## 11. State Models

### ExploreState

```swift
enum ExploreState {
  case none
  case loading
  case loaded([EpisodeRowState])
  case empty
  case failed(String)
}

struct EpisodeRowState: Equatable, Identifiable {
  let episode: Episode
  let isKept: Bool
  let playbackState: PlaybackState?
}
```

### KeepsState

```swift
enum KeepsState {
  case none
  case loading
  case loaded([EpisodeRowState])
  case empty
  case failed(String)
}
```

## 12. Error Handling

Repository implementations should expose domain-level errors instead of raw transport errors.

```swift
public enum EpisodeRepositoryError: Error {
  case invalidURL
  case networkFailure
  case httpStatus(Int)
  case decodingFailed
  case feedURLNotFound
  case noPlayableEpisodes
}
```

User-facing UI should map errors to short messages:

- Network failure: “Unable to load episodes.”
- No playable episodes: “No playable episodes found.”
- Playback failure: “Unable to play this episode.”
- Keep persistence failure: “Unable to update Keep.”

## 13. Ranking Logic

MVP ranking is deterministic and simple.

1. Fetch top podcasts from Apple RSS.
2. Resolve each podcast feed URL.
3. Fetch recent episodes from each feed.
4. Take the latest playable episode from each podcast.
5. Preserve podcast rank as the primary ranking signal.
6. Use publish date as secondary ranking within equal rank groups.
7. Trim to requested episode limit.

This should be documented as “popular podcasts' recent episodes,” not true episode-level popularity. PRD risk remains open until a better episode-level data source is found.

## 14. Analytics

Analytics is optional for this sample project because KeepCast is not planned for production publishing. If added, use a lightweight `AnalyticsLogging` interface so implementation can be local/no-op in MVP.

```swift
public protocol AnalyticsLogging {
  func log(_ event: AnalyticsEvent)
}

public struct AnalyticsEvent {
  public let name: String
  public let properties: [String: String]
}
```

Suggested optional events:

- `app_opened`
- `explore_loaded`
- `explore_load_failed`
- `episode_impression`
- `episode_opened`
- `episode_kept`
- `episode_unkept`
- `keep_list_opened`
- `playback_started`
- `playback_failed`
- `rss_feed_parse_failed`

## 15. Performance Requirements

- Explore content visible: p50 <= 2s, p95 <= 5s
- First playback start: p50 <= 2s after valid audio URL tap
- Keep/unkeep UI response: <= 100ms perceived latency
- Main-thread RSS parsing: forbidden
- Feed fetch fan-out should be capped. MVP default: max 10 feeds per refresh.
- Network requests should have timeout. MVP default: 10s.

## 16. Testing Strategy

### Unit Tests

- RSS parser handles valid RSS
- RSS parser skips malformed item
- RSS parser parses `itunes:duration`
- episode identity fallback order
- KeepRepository keep/unkeep/idempotency
- ExploreInteractor loading success
- ExploreInteractor partial feed failure
- ExploreInteractor total failure

### Integration Tests

- PodcastRepository live tests can remain separate from normal test scheme.
- Repository tests should use `URLSessionMock`.
- Playback tests should use a fake playback controller, not `AVPlayer`.

### UI State Tests

- loading state
- empty state
- failed state
- keep selected state
- playback state rendering

## 17. Implementation Plan

### Phase 1: Core Data Layer

- Add `Episode` and related entities.
- Add repository interfaces.
- Implement Apple top podcast fetch.
- Implement iTunes lookup feed URL resolver.
- Implement RSS parser.

### Phase 2: Keep Layer

- Add local keep repository.
- Add persistence abstraction if missing.
- Add unit tests for keep/unkeep behavior.

### Phase 3: Explore Feature

- Add Explore RIB files.
- Render episode-first list.
- Wire keep/unkeep actions.
- Add loading, empty, failed states.

### Phase 4: Playback

- Add playback controller interface.
- Implement AVPlayer-backed controller.
- Wire play action from Explore and Keep list.

### Phase 5: Keeps Feature

- Add Keep list screen.
- Load local kept episodes.
- Support unkeep and playback.

## 18. Open Technical Questions

1. Should `Explore` replace `TopPodcasts`, or should `TopPodcasts` remain as a spike until Explore is complete?
2. Should local persistence use JSON file, UserDefaults, or SQLite-like storage for MVP?
3. Should playback controller live in Platform or Core?
4. Should feed URL resolution be cached? If yes, what TTL?
5. Should Explore fetch episodes from top 10 podcasts only, or fan out until it reaches 30 playable episodes?
6. Should background audio controls be included in MVP or deferred?
