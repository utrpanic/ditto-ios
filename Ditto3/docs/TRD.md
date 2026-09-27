# TRD: Ditto3 Podcast Architecture Sample

## 1. Technical Objective

Ditto3는 RIBs의 개발 모델을 유지하면서 기능의 소유권과 수명을 UIKit VC tree에 맡기는 RIBsLite architecture sample이다. 기술 목표는 Podcast app의 현실적인 화면 구성과 공유 상태를 구현하면서 다음을 검증하는 것이다.

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
Episode -> Play / Play Next / Add to Queue -> Player Queue
```

- Podcast만 Follow한다.
- Episode는 Keep하지 않는다.
- Latest는 Follow와 remote feed에서 파생한다.
- Queue는 `Play Next`와 `Add to Queue`로 명시적으로 구성한다.
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
  Playback/Implementation

Platform
  URLSessionProtocol
  UserDefaultsProtocol
  AVPlayerProtocol
  AVAudioSessionProtocol
  MPRemoteCommandCenterProtocol
  MPNowPlayingInfoCenterProtocol
```

Feature target은 Repository interface와 Entity에만 의존한다. concrete implementation은 AppComponent가 생성하고 dependency protocol을 통해 주입한다.

Playback은 같은 규칙을 따른다. Feature는 Core의 `PlaybackControlling`만 사용하고, Core의 `PlaybackControllerImp`가 Platform system protocol을 통해 Apple SDK를 사용한다. Platform은 별도 adapter 객체를 만들지 않고 해당 system type을 protocol에 직접 conform시킨다.

```text
Feature.Player
-> Core.Playback Interface
<- Core.Playback Implementation
-> Platform system protocol
-> AVFoundation / MediaPlayer system type
```

## 4. Ditto3 Feature Composition

RIBsLite는 VC가 Interactor를 소유하고, Presentable·PresentableListener를 StateStore 관찰과 `sendAction`으로 대체한다. 이 소유권과 표현 계약 위에 Ditto3의 화면을 구성한다. SwiftUI 호스팅과 Composition Root는 샘플의 선택이다. AppComponent는 각 Feature의 Dependency를 직접 충족해 leaf 의존성 변경을 모든 ancestor가 전달하는 부담을 줄인다. 이 DI 방식은 RIBsLite의 필수 조건이 아니며, 객체의 공유 범위는 별도로 정한다.

### 4.1 VC Tree

```text
MainViewController
├── Discover navigation controller
│   ├── DiscoverViewController
│   ├── PodcastViewController
│   └── EpisodeViewController
├── Latest navigation controller
│   ├── LatestViewController
│   └── EpisodeViewController
├── Library navigation controller
│   ├── LibraryViewController
│   ├── PodcastViewController
│   └── EpisodeViewController
├── Search navigation controller
│   ├── SearchViewController
│   ├── PodcastViewController
│   └── EpisodeViewController
└── PlayerViewController
```

각 navigation controller 아래는 해당 탭에서 push할 수 있는 화면의 예시다. Podcast와 Episode는 이동 경로상 이어져도 VC 소유 관계에서는 같은 navigation stack에 놓인다.

Main은 tab child와 Player child의 부착 및 화면 배치를 담당한다. Player는 세션 유무와 관계없이 Main에 상주하고, 세션에 따라 MiniPlayer 표시만 바뀐다. Expanded Player와 Queue는 Player 내부의 SwiftUI 표현이며 별도 Riblet이 아니다. Player의 동적 제거·교체는 지원하지 않는다.

### 4.2 Presentation Contract and SwiftUI Composition

Interactor는 VC나 Presenter를 직접 참조하지 않고 StateStore를 변경한다. Presentable의 표현 메서드는 상태 관찰로, PresentableListener의 입력 메서드는 `sendAction(Action)`으로 대체한다. 기능 간 통신을 위한 Listener는 유지한다. VC는 Interactor를 소유하고 상태와 입력 경로를 View에 연결하며, 상태 쓰기는 Interactor가 담당한다는 컨벤션을 따른다.

- Feature의 ViewController는 `UIHostingController<StateReader<...>>` 패턴을 사용한다.
- SwiftUI View는 state와 `sendAction` closure만 받는다.
- Store와 Repository는 View interface에 노출하지 않는다.
- UIKit container가 tab, navigation, persistent MiniPlayer의 배치를 담당한다.

`StateStore<State>`는 `@MainActor @Observable` reference type이며, Interactor가 생성하고 state를 변경한다. `StateReader`는 주입된 Store를 일반 `let` property로 보관하고 `body`에서 `store.state`를 읽어 SwiftUI의 Observation 추적에 참여한다. View에 Store나 Binding을 노출하지 않으며, 기존 value-type state와 action interface를 유지한다. 추적 단위는 Store의 `state` property이므로 state 내부 필드별로 관찰을 분리하지 않는다.

UIKit의 Main 탭 선택과 Player visibility는 Store의 `stateDidChange: AnyPublisher<State, Never>`를 구독한다. Store는 `state.didSet`에서 반영된 state를 MainActor 위에서 동기 발행하므로, 구독 callback에서 action을 보내도 Interactor는 해당 mutation이 반영된 state를 읽는다. Publisher는 초기값을 replay하지 않으며, 구독자는 최초 표시 시 `store.state`를 읽는다. Store는 같은 값의 재할당도 발행하고, UI 구독자가 `removeDuplicates()`를 적용한다. 호출부에서 scheduler를 변경하지 않으며, 비동기 지연·관찰 재등록·변경 병합은 하지 않는다.

SwiftUI는 Observation으로 자동 갱신하고, UIKit은 변경 후 Publisher를 사용하는 구조다. UIKit callback은 ViewController를 약하게 참조하고, VC가 소유한 `AnyCancellable`은 VC 해제 시 구독을 취소한다. Player 구독은 MiniPlayer의 화면 표시 여부와 무관하게 유지한다. Main은 동기 구독으로 선택을 반영하므로 `selectTab` 직후 `push`도 올바른 navigation stack을 사용한다.

### 4.3 Feature Reuse

Podcast와 Episode Builder는 진입한 parent feature와 무관하게 동일한 dependency와 input entity로 화면을 생성한다.

- Podcast entry points: Discover, Search, Library
- Episode entry points: Podcast, Latest, Search, Queue

### 4.4 Ownership and Lifecycle

- UIKit VC tree가 Feature ViewController의 수명을 소유한다.
- ViewController는 Interactor를 강하게 소유하고, Interactor는 Router를 강하게 소유한다.
- Router는 ViewController를 약하게 참조해 `ViewController -> Interactor -> Router -> ViewController` 순환 참조를 만들지 않는다.
- 다른 강한 참조가 없다면 ViewController 해제와 함께 Interactor도 해제된다. 진행 중인 Task가 수명을 연장할 수 있으며, 장기 stream observation은 Interactor의 deinit에서 취소한다.
- 별도 Router attach가 없으므로 각 VC 부착 경로에서 활성화를 처리하는 대신, Builder가 Router와 Listener 연결 후 `interactor.activate()`를 한 번 호출하도록 단순화한다. `build()`는 생성과 시작을 포함하고, `didBecomeActive()`의 초기 작업은 VC 부착이나 화면 표시 전에 시작할 수 있다.
- 공통 deactivate lifecycle은 사용하지 않는다. UIKit state 구독은 weak callback으로 VC 수명을 연장하지 않으며 VC가 소유한 cancellable로 수명을 관리한다.
- 일회성 조회, 저장, 재생 작업의 완료·취소와 상태 반영 정책은 각 Feature가 관리하며, VC 해제가 모든 작업의 즉시 종료를 보장하지는 않는다.

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
- Add to Queue

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
  func dequeue() async throws -> QueueItem?
  func playNext(_ episode: Episode) async throws
  func addToQueue(_ episode: Episode) async throws
  func move(episodeID: EpisodeID, to index: Int) async throws
  func remove(episodeID: EpisodeID) async throws
  func removeAll() async throws
  func changes() -> AsyncStream<Void>
}
```

`dequeue`는 Queue의 첫 항목을 저장소에서 원자적으로 제거해 반환한다. `playNext`는 EpisodeID 기준으로 기존 항목을 제거한 뒤 Queue의 첫 위치에 삽입한다. `addToQueue`는 같은 방식으로 중복을 제거한 뒤 마지막 위치에 삽입한다.

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
  func restore(_ session: PlaybackSession) async
  func play() async
  func pause()
  func seek(to position: TimeInterval) async
  func skipBackward()
  func skipForward()
  func stateChanges() -> AsyncStream<PlaybackState>
  func completionEvents() -> AsyncStream<PlaybackSession>
}
```

Player Interactor는 `PlaybackControlling`과 persistence repository를 조합한다. 재생 완료 이벤트를 받으면 Queue의 첫 항목을 `dequeue`하고 다음 Episode를 재생한다. Feature는 `AVPlayer`에 직접 의존하지 않는다. `PlaybackControllerImp`는 Core/Playback/Implementation에 위치하고, AppComponent가 실제 Apple system 객체를 주입한다.

```swift
PlaybackControllerImp(
  player: AVPlayer(),
  audioSession: AVAudioSession.sharedInstance(),
  remoteCommandCenter: MPRemoteCommandCenter.shared(),
  nowPlayingInfoCenter: MPNowPlayingInfoCenter.default()
)
```

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

관련 Interactor는 activation 시 필요한 stream만 구독하고 deinit에서 장기 observation task를 취소한다. 일회성 조회·저장·재생 작업은 VC 해제 후에도 완료한다. Repository snapshot을 다시 읽는 방식으로 event 유실과 중복 전달에 안전하게 만든다. Repository/Playback의 AsyncStream은 그대로 유지하며, SwiftUI state 추적에는 Observation, UIKit state 구독에는 Store의 변경 후 Publisher를 사용한다.

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

## 12. Play and Queue Flows

### Play

```text
User taps Play
-> EpisodeInteractor handles the action
-> PlaybackControlling.play(episode)
-> PlayerInteractor observes shared playback state
-> PlayerListener reports visibility to MainInteractor
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

### Add to Queue

```text
User taps Add to Queue
-> PlaybackQueueRepository.addToQueue(episode)
-> deduplicate and place at the end of Queue
-> Player reloads Queue
```

### Automatic Queue Progression

```text
AVPlayer item finishes
-> PlaybackControlling emits the completed session and becomes idle
-> persistent Player dequeues the first QueueItem
-> if an item exists, PlaybackControlling starts its Episode
-> otherwise Player remains idle
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
- PlaybackQueueRepository playNext/addToQueue/deduplication/reorder/removal/persistence
- PlaybackSessionRepository save/load/clear/version handling
- Latest partial aggregation, deduplication, sorting, limit
- Podcast follow optimistic update and rollback
- Episode Play/Play Next/Add to Queue action forwarding
- Player state transition and resume behavior

### Feature Composition Tests

- Podcast build from Discover, Search, Library
- Episode build from Podcast, Latest, Search, Queue
- Main attaches persistent Player independently of selected tab
- Player switches mini/expanded state without creating another playback owner
- Interactor activation starts stream observations and deinit cancels them
- StateStore replacement/nested mutation participates in Observation tracking
- StateReader updates hosted SwiftUI content after repeated state changes
- Main tab selection remains synchronous for immediate navigation pushes
- StateStore publisher emits committed state synchronously for replacement/nested mutation and stops delivery after cancellation
- Player visibility callback can send an action that reads committed playback state and mutates the same store
- UIKit subscriptions update Main selection and hidden Player visibility synchronously without retaining ViewController/Interactor

### Manual Scenarios

1. Follow a Podcast in Search and verify Library/Latest.
2. Open the same Podcast from Library and verify Follow state.
3. Open an Episode from Latest, use Play Next and Add to Queue, and verify Player Queue.
4. Start playback, switch tabs, and verify MiniPlayer continuity.
5. Terminate and relaunch the app, then resume from the saved position.

## 17. Implementation Sequence

1. Implement Following persistence and Podcast Follow UI.
2. Implement Library and Latest features.
3. Add Playback interface and AVPlayer adapter.
4. Attach persistent Player to Main.
5. Implement Queue, Play Next, and Add to Queue.
6. Add playback session persistence and resume.

Each step should remain a focused commit and preserve a buildable project.

## 18. Deep Link Navigation

Deep link navigation is split into route resolution and navigation execution. The current implementation covers navigation execution for an already resolved domain route; external URL parsing and entity resolution remain separate concerns.

`DeepLinkRouter` and `MainNavigation` are Ditto3-specific application types, not part of RIBsLite's architecture contract. They implement this sample's deep-link navigation independently of a Router tree.

```text
SceneDelegate.handleDeepLink(DeepLink)
-> App.DeepLinkRouter
   ├─ main(tab): select the requested tab in the existing Main
   ├─ podcast(Podcast): build and push Podcast on the selected tab
   └─ episode(Episode): build and push Episode on the selected tab
```

- Main owns one `UINavigationController` per tab rather than a shared navigation stack.
- A Main destination changes only the selected tab and preserves each tab's stack.
- Podcast and Episode destinations use the currently selected tab's navigation controller.
- `DeepLinkRouter` belongs to the App composition layer and owns Podcast/Episode feature construction.
- Main exposes `MainNavigation`, implemented by `MainRouter`, for tab selection and pushing a view controller on the selected tab. Internal `MainRouting` adds child attachment with per-call listeners and Episode routing. Tab selection does not initialize children.
- `MainBuilder` creates and wires the objects, then calls `interactor.activate()` to configure children before returning. MainViewController subclasses UITabBarController; viewDidLoad handles UI setup and state binding only. SceneDelegate does not need to force view loading before connecting DeepLinkRouter. MainRouter does not retain an interactor, and its child view-controller references are weak. Routers guard their source view controller before building destinations to avoid starting features after the source has been released.
- `DeepLinkRouter` receives Podcast and Episode builders through `DeepLinkDependency`, which `AppComponent` satisfies as the composition root.
- Main and `MainInteractor` remain unaware of deep links and do not depend on Podcast/Episode solely for deep-link routing.
- URL schemes, URL parameters, and the resolver that produces `Podcast` or `Episode` are not defined at this stage.

## 19. Explicit Non-goals

- viewless Riblet
- Episode Keep or Saved Episodes
- account and cross-device sync
- paid Subscription
- explicit download UI
- persistent audio cache and guaranteed offline playback
- private RSS authentication
- recommendation engine
- production analytics
