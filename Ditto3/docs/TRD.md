# TRD: Ditto3 Podcast Architecture Sample

## 1. Technical Objective

Ditto3는 view-controller-centered RIB tree를 사용하는 RIBsLite architecture sample이다. 기술 목표는 Podcast app의 현실적인 화면 구성과 공유 상태를 구현하면서 다음을 검증하는 것이다.

1. Feature별 Builder, Interactor, Router, ViewController 경계
2. UIKit VC tree와 SwiftUI view의 조합
3. 동일 Feature의 복수 진입점
4. root에 지속되는 Player child
5. Repository 기반 공유 상태와 feature 간 갱신
6. local persistence와 playback session 복원

viewless Riblet은 지원하지 않는다. 화면이 없는 domain behavior는 Repository 또는 service가 담당한다.

## 2. Domain Rules

```text
Podcast -> Episode
Podcast -> Follow -> Library
Followed Podcasts -> Latest Episodes
Episode -> Play / Play Next -> Player Queue
```

- Podcast만 Follow한다.
- Episode는 Keep하지 않는다.
- Latest는 Follow와 remote feed에서 파생한다.
- Queue는 `Play Next`로 명시적으로 구성한다.
- Follow 상태, Latest, Queue, playback session은 서로 다른 책임이다.

## 3. Module Boundaries

```text
App
  AppComponent

Architecture
  RIBsLite

Feature
  Main
  Discover
  Latest
  Library
  Search
  Podcast
  Episode
  Player

Core
  Entity
  Repository/Interface
  Repository/Implementation
  Playback/Interface

Platform
  URLSessionProtocol
  UserDefaultsProtocol
  AVPlayer adapter
```

Feature target은 Repository interface와 Entity에만 의존한다. concrete implementation은 AppComponent가 생성하고 dependency protocol을 통해 주입한다.

## 4. RIBsLite Composition

### 4.1 VC Tree

```text
MainViewController
├── Discover navigation controller
│   └── PodcastViewController
│       └── EpisodeViewController
├── Latest navigation controller
│   └── EpisodeViewController
├── Library navigation controller
│   └── PodcastViewController
│       └── EpisodeViewController
├── Search navigation controller
│   ├── PodcastViewController
│   └── EpisodeViewController
└── PlayerViewController
    ├── MiniPlayer presentation
    └── Expanded Player / Queue presentation
```

Main은 tab child와 Player child의 attach/detach 및 화면 배치를 담당한다. Player는 재생 session이 존재하는 동안 tab 전환과 navigation stack 변화에 관계없이 유지된다.

### 4.2 SwiftUI Composition

- Feature의 ViewController는 `UIHostingController<StateReader<...>>` 패턴을 사용한다.
- SwiftUI View는 state와 `sendAction` closure만 받는다.
- Store와 Repository는 View interface에 노출하지 않는다.
- UIKit container가 tab, navigation, persistent MiniPlayer의 배치를 담당한다.

### 4.3 Feature Reuse

Podcast와 Episode Builder는 진입한 parent feature와 무관하게 동일한 dependency와 input entity로 화면을 생성한다.

- Podcast entry points: Discover, Search, Library
- Episode entry points: Podcast, Latest, Search, Queue

## 5. Feature Responsibilities

### Main

- primary tab 구성
- root-level Player child 배치
- app-wide navigation presentation 경계 제공

### Discover

- 인기 Podcast 조회
- Podcast row 표시
- Podcast feature로 route

### Latest

- followed Podcast 조회
- 각 Podcast의 최신 Episode 조회
- partial result 병합 및 정렬
- Episode feature로 route

### Library

- followed Podcast 표시
- empty state 제공
- Podcast feature로 route

### Search

- Podcast/Episode segmented search
- 결과 종류에 맞는 detail feature로 route

### Podcast

- Podcast metadata 및 최신 Episode 표시
- Follow/Unfollow
- Episode feature로 route

### Episode

- Episode metadata 표시
- Play
- Play Next

### Player

- `AVPlayer` transport 제어
- MiniPlayer와 expanded presentation state
- Queue 표시와 편집
- playback progress 발행
- current session 및 resume position 저장
- 완료 시 다음 Queue 항목 재생

Queue는 초기에는 Player feature 내부 view/state로 구현한다. 독립 lifecycle이나 navigation 책임이 필요해질 때만 Player의 child Riblet으로 분리한다.

## 6. Core Entities

기존 `Podcast`, `Episode`, `PodcastID`, `EpisodeID`를 유지하고 다음 entity를 추가한다.

```swift
public struct FollowedPodcast: Equatable, Sendable {
  public let podcast: Podcast
  public let followedAt: Date
}

public struct QueueItem: Equatable, Sendable {
  public let episode: Episode
  public let enqueuedAt: Date
}

public struct PlaybackSession: Equatable, Sendable {
  public let episode: Episode
  public let position: TimeInterval
  public let updatedAt: Date
}
```

전체 snapshot을 저장해 remote lookup 실패 시에도 Library, Queue, 복원된 MiniPlayer의 최소 UI를 구성할 수 있게 한다.

## 7. Repository Interfaces

구체적인 동시성 표기는 구현 시 Swift concurrency isolation에 맞춰 확정한다.

### PodcastRepository

```swift
public protocol PodcastRepository {
  func fetchTopPodcasts(limit: Int) async throws -> [Podcast]
  func searchPodcasts(term: String, limit: Int) async throws -> [Podcast]
  func resolveFeedURL(podcastID: PodcastID) async throws -> URL
}
```

### EpisodeRepository

```swift
public protocol EpisodeRepository {
  func fetchEpisodes(podcast: Podcast, feedURL: URL, limit: Int?) async throws -> [Episode]
  func searchEpisodes(term: String, limit: Int) async throws -> [Episode]
}
```

### FollowingRepository

```swift
public protocol FollowingRepository {
  func fetchFollowedPodcasts() async throws -> [FollowedPodcast]
  func isFollowing(podcastID: PodcastID) async throws -> Bool
  func follow(_ podcast: Podcast) async throws
  func unfollow(podcastID: PodcastID) async throws
  func changes() -> AsyncStream<Void>
}
```

### PlaybackQueueRepository

```swift
public protocol PlaybackQueueRepository {
  func fetchQueue() async throws -> [QueueItem]
  func playNext(_ episode: Episode) async throws
  func move(episodeID: EpisodeID, to index: Int) async throws
  func remove(episodeID: EpisodeID) async throws
  func removeAll() async throws
  func changes() -> AsyncStream<Void>
}
```

`playNext`는 EpisodeID 기준으로 기존 항목을 제거한 뒤 Queue의 첫 위치에 삽입한다.

### PlaybackSessionRepository

```swift
public protocol PlaybackSessionRepository {
  func loadSession() async throws -> PlaybackSession?
  func saveSession(_ session: PlaybackSession) async throws
  func clearSession() async throws
}
```

## 8. Playback Interface

```swift
public enum PlaybackState: Equatable, Sendable {
  case idle
  case loading(PlaybackSession)
  case paused(PlaybackSession)
  case playing(PlaybackSession)
  case failed(PlaybackSession?, message: String)
}

public protocol PlaybackControlling: AnyObject {
  func play(_ episode: Episode) async
  func play()
  func pause()
  func seek(to position: TimeInterval) async
  func skipBackward()
  func skipForward()
  func stateChanges() -> AsyncStream<PlaybackState>
}
```

Player Interactor는 `PlaybackControlling`과 persistence repository를 조합한다. Feature는 `AVPlayer`에 직접 의존하지 않는다.

Playback foundation의 system integration 범위는 다음과 같다.

- audio session은 `.playback` category와 `.spokenAudio` mode를 사용하고 background audio mode를 활성화한다.
- 잠금 화면은 play, pause, playback position 변경, 15초 뒤로, 30초 앞으로를 지원한다.
- Now Playing에는 Episode 제목, Podcast 제목, 전체 길이, 현재 위치, 재생 속도를 제공한다.
- 원격 artwork 로딩, 명시적 download, persistent audio cache, guaranteed offline playback은 포함하지 않는다.

## 9. State Synchronization

RIB listener는 child-to-parent navigation event와 완료 event에 사용한다. app-wide domain state를 listener chain으로 전달하지 않는다.

- Follow 변경: `FollowingRepository.changes()`
- Queue 변경: `PlaybackQueueRepository.changes()`
- 재생 상태: `PlaybackControlling.stateChanges()`

관련 Interactor는 active 상태에서 필요한 stream만 구독하고 deactivation 시 task를 취소한다. Repository snapshot을 다시 읽는 방식으로 event 유실과 중복 전달에 안전하게 만든다.

## 10. Latest Aggregation

```text
FollowingRepository.fetchFollowedPodcasts()
-> resolve missing feed URLs
-> fetch recent episodes for each Podcast concurrently
-> retain successful results when individual feeds fail
-> deduplicate by EpisodeID
-> sort by publishedAt descending
-> prefix 20
```

- Follow한 Podcast가 없으면 empty state를 표시한다.
- 일부 feed가 실패하면 성공한 Episode와 partial failure indication을 표시한다.
- 모든 feed가 실패하면 failure state를 표시한다.
- refresh는 최초 진입, foreground 복귀, 사용자 입력으로 수행한다.

## 11. Follow Flow

```text
User taps Follow in Podcast
-> PodcastInteractor.sendAction(.toggleFollow)
-> optimistic PodcastState update
-> FollowingRepository.follow/unfollow
-> repository change event
-> active Library and Latest Interactors reload snapshots
-> failure restores previous PodcastState
```

Podcast VC가 어느 entry point에서 생성됐는지에 관계없이 같은 동작을 사용한다.

## 12. Play and Play Next Flows

### Play

```text
User taps Play
-> source Interactor notifies/routes through its owning tree
-> persistent Player receives Episode
-> PlaybackControlling.play(episode)
-> Main reveals MiniPlayer
```

새 Episode를 즉시 재생해도 기존 Queue 순서는 유지한다.

### Play Next

```text
User taps Play Next
-> if no current session, start the Episode immediately
-> otherwise PlaybackQueueRepository.playNext(episode)
-> deduplicate and place at queue index 0
-> Player reloads Queue
```

Follow와 Queue는 독립적이므로 Unfollow가 Queue를 변경하지 않는다.

## 13. Resume Playback

AVPlayer의 buffer나 system cache에 영속성을 의존하지 않는다.

1. Player는 periodic time observer로 current position을 관찰한다.
2. 재생 중 제한된 주기마다 session을 저장한다.
3. pause, background, current Episode 교체 시 즉시 저장한다.
4. 앱 시작 시 저장된 session을 읽고 paused state와 MiniPlayer를 복원한다.
5. 사용자가 Play하면 remote asset을 준비하고 저장 위치로 seek한 뒤 재생한다.
6. 정상 완료 시 session을 지우고 Queue의 첫 항목을 재생한다.

위 동작은 네트워크 연결을 전제로 한다. 앱이 관리하는 audio file download와 guaranteed offline playback은 구현하지 않는다.

## 14. Persistence

Following, Queue, PlaybackSession은 version을 포함한 JSON snapshot으로 local persistence에 저장한다.

- write는 전체 snapshot 단위로 수행한다.
- 알 수 없는 version 또는 손상된 payload는 crash를 유발하지 않는다.
- Queue와 PlaybackSession은 full Episode snapshot을 저장한다.
- Following은 full Podcast snapshot을 저장한다.
- schema migration이 없으면 unsupported version을 empty 또는 nil state로 처리하고 진단 가능한 error를 남긴다.

## 15. Error Handling

- Discover/Search remote failure: retry 가능한 failure state
- Latest partial failure: 성공 결과 유지
- Follow persistence failure: optimistic state rollback
- Queue persistence failure: action failure 표시 및 이전 Queue 유지
- playback failure: current Episode metadata와 retry 유지
- resume seek failure: 처음부터 재생할지 사용자에게 명확히 표시

## 16. Testing Strategy

### Unit Tests

- FollowingRepository follow/unfollow/idempotency/persistence
- PlaybackQueueRepository playNext/deduplication/reorder/removal/persistence
- PlaybackSessionRepository save/load/clear/version handling
- Latest partial aggregation, deduplication, sorting, limit
- Podcast follow optimistic update and rollback
- Episode Play/Play Next action forwarding
- Player state transition and resume behavior

### Feature Composition Tests

- Podcast build from Discover, Search, Library
- Episode build from Podcast, Latest, Search, Queue
- Main attaches persistent Player independently of selected tab
- Player switches mini/expanded state without creating another playback owner
- Interactor activation starts stream observations and deactivation cancels them

### Manual Scenarios

1. Follow a Podcast in Search and verify Library/Latest.
2. Open the same Podcast from Library and verify Follow state.
3. Open an Episode from Latest, use Play Next, and verify Player Queue.
4. Start playback, switch tabs, and verify MiniPlayer continuity.
5. Terminate and relaunch the app, then resume from the saved position.

## 17. Implementation Sequence

1. Implement Following persistence and Podcast Follow UI.
2. Implement Library and Latest features.
3. Add Playback interface and AVPlayer adapter.
4. Attach persistent Player to Main.
5. Implement Queue and Play Next.
6. Add playback session persistence and resume.

Each step should remain a focused commit and preserve a buildable project.

## 18. Explicit Non-goals

- viewless Riblet
- Episode Keep or Saved Episodes
- account and cross-device sync
- paid Subscription
- explicit download UI
- persistent audio cache and guaranteed offline playback
- private RSS authentication
- recommendation engine
- production analytics
