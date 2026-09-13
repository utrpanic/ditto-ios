# PRD: Ditto3 Podcast Architecture Sample

## 1. Purpose

Ditto3는 특정 시장성과 사용성 지표를 검증하기 위한 제품이 아니다. 일관된 podcast app 시나리오를 구현하면서 view-controller-centered RIB tree인 RIBsLite의 적용 범위와 한계를 확인하는 architecture sample이다.

제품 요구사항은 architecture를 검증할 만큼 현실적이어야 하지만, 계정·결제·추천처럼 architecture 실험에 불필요한 범위는 포함하지 않는다.

## 2. Terminology

- **Podcast:** 하나의 feed 아래 여러 Episode를 제공하는 프로그램 단위
- **Episode:** 사용자가 탐색하고 재생하는 개별 콘텐츠 단위
- **Follow:** Podcast를 Library에 추가하고 최신 Episode를 받아보는 행위
- **Library:** Follow한 Podcast의 모음
- **Latest:** Follow한 Podcast에서 수집한 최신 Episode의 통합 피드
- **Queue:** 현재 Episode 다음에 재생할 Episode의 명시적 순서
- **Play Next:** 선택한 Episode를 Queue의 최상단에 배치하는 행위
- **Player:** 현재 재생, Queue, 이어 듣기 상태를 소유하는 기능

`Show`, `Bookmark`, `Keep`, `Saved Episode`, `Subscription`, `Playlist`는 같은 개념을 가리키는 대체 용어로 사용하지 않는다. 유료 상품과 혼동할 수 있는 `Subscription` 대신 `Follow`를 사용하고, 재생 순서는 `Queue`로 부른다.

## 3. Product Model

Ditto3의 기본 관계는 다음과 같다.

```text
Podcast -> Episode
Podcast -> Follow -> Library
Followed Podcasts -> Latest Episodes
Episode -> Play / Play Next -> Player Queue
```

Podcast가 Follow 대상이고 Episode가 재생 대상이다. Episode를 별도로 Keep하거나 Library에 저장하지 않는다.

Latest와 Queue는 다른 목록이다.

- Latest는 Follow 상태와 remote feed에서 파생된다.
- Queue는 사용자의 `Play Next` 입력으로 생성된다.
- Podcast를 Unfollow해도 이미 Queue에 들어간 Episode는 제거하지 않는다.

## 4. Information Architecture

앱은 다음 네 개의 primary tab을 제공한다.

1. **Discover:** 인기 Podcast 탐색
2. **Latest:** Follow한 Podcast의 최신 Episode 통합 목록
3. **Library:** Follow한 Podcast 목록
4. **Search:** Podcast와 Episode 검색

재생이 시작되면 MiniPlayer가 모든 tab 위에서 유지된다. MiniPlayer를 선택하면 expanded Player가 열리고, Player 안에서 Queue를 확인한다.

## 5. User Flows and Acceptance Criteria

### 5.1 Discover Podcasts

사용자는 인기 Podcast를 탐색하고 Podcast 상세 화면으로 이동할 수 있다.

- Podcast row는 artwork, title, author를 표시한다.
- Podcast row를 선택하면 동일한 Podcast feature로 이동한다.
- loading, empty, partial failure, failure 상태를 구분한다.

### 5.2 Follow a Podcast

사용자는 Podcast 상세 화면에서 Podcast를 Follow하거나 Unfollow할 수 있다.

- Follow action은 한 번의 입력으로 완료된다.
- Follow 상태는 앱 재실행 후에도 유지된다.
- 같은 Podcast를 중복 Follow하지 않는다.
- Podcast 상세의 모든 진입점에서 같은 Follow 상태를 표시한다.
- Unfollow하면 Library와 이후 Latest 갱신 대상에서 제거된다.

### 5.3 Browse the Library

사용자는 Follow한 Podcast를 Library에서 확인할 수 있다.

- Library는 Follow한 Podcast를 표시한다.
- 항목을 선택하면 Podcast 상세 화면으로 이동한다.
- Follow한 Podcast가 없으면 empty state를 표시한다.

### 5.4 Browse Latest Episodes

사용자는 Follow한 모든 Podcast의 최신 Episode를 한 목록에서 확인할 수 있다.

- Latest는 각 Podcast의 public feed에서 Episode를 가져온다.
- Episode는 `publishedAt` 내림차순으로 병합한다.
- 최대 20개를 표시한다.
- 앱 실행, foreground 복귀, 사용자 새로고침 시 갱신한다.
- 일부 Podcast의 feed 조회 실패가 전체 목록을 실패시키지 않는다.
- 항목을 선택하면 Episode 상세 화면으로 이동한다.

### 5.5 Search

사용자는 하나의 Search feature에서 Podcast와 Episode를 각각 검색할 수 있다.

- Podcast와 Episode tab을 제공한다.
- Podcast 결과는 Podcast 상세 화면으로 이동한다.
- Episode 결과는 Episode 상세 화면으로 이동한다.

### 5.6 Episode Detail

사용자는 Episode 정보를 확인하고 재생할 수 있다.

- title, Podcast title, artwork, description, publish date, duration을 가능한 범위에서 표시한다.
- `Play`는 선택한 Episode를 즉시 재생한다.
- `Play Next`는 현재 Episode 바로 다음 위치에 추가한다.
- 이미 Queue에 있는 Episode에 `Play Next`를 실행하면 중복하지 않고 최상단으로 이동한다.
- Episode Keep 또는 Save action은 제공하지 않는다.

### 5.7 Player and Queue

재생 중에는 모든 tab에서 MiniPlayer를 사용할 수 있다.

- MiniPlayer는 artwork, Episode title, play/pause를 제공한다.
- MiniPlayer를 선택하면 expanded Player를 연다.
- expanded Player는 현재 Episode, 진행률, seek, play/pause, 앞뒤 건너뛰기, Queue 진입을 제공한다.
- Queue에서 Episode 선택, 순서 변경, 개별 제거, 전체 제거가 가능하다.
- Episode가 완료되면 Queue의 다음 Episode를 재생한다.
- Queue와 현재 재생 session은 앱 재실행 후에도 유지된다.
- 현재 재생 Episode가 없을 때 `Play Next`를 실행하면 해당 Episode를 즉시 재생한다.

### 5.8 Resume Playback

사용자는 앱을 종료했다가 다시 실행해도 마지막 Episode를 이어서 재생할 수 있다.

- 현재 Episode snapshot과 재생 위치를 local persistence에 저장한다.
- 재생 중 주기적으로 위치를 저장한다.
- pause, background 진입, Episode 교체 시 위치를 즉시 저장한다.
- 앱 재실행 시 자동 재생하지 않고 복원된 MiniPlayer를 표시한다.
- 사용자가 Play하면 remote audio를 다시 열고 저장된 위치로 seek한 뒤 재생한다.
- 재생 완료된 Episode의 resume position은 제거한다.

이어 듣기는 오디오 파일의 영속 저장을 요구하지 않는다. AVPlayer의 임시 buffering은 구현 세부사항이며, 앱이 관리하는 offline audio cache로 간주하지 않는다.

## 6. Product Rules

- Podcast는 Follow 대상이다.
- Episode는 Play와 Play Next 대상이다.
- Latest는 자동 생성 피드이고 Queue는 명시적 사용자 입력이다.
- Queue 항목과 Follow 상태는 서로 독립적이다.
- remote metadata가 없으면 값을 임의로 생성하지 않는다.
- stable identifier를 기준으로 Podcast, Episode, Queue 항목의 중복을 방지한다.
- local state 변경은 관련 화면에 일관되게 반영한다.

## 7. Architecture Validation Scenarios

다음 시나리오가 RIBsLite 검증의 완료 기준이다.

1. Podcast feature가 Discover, Search, Library에서 동일하게 재사용된다.
2. Episode feature가 Podcast, Latest, Search, Queue에서 동일하게 재사용된다.
3. 한 화면의 Follow 변경이 Library, Latest, 다른 Podcast 상세에 반영된다.
4. Episode의 Play 또는 Play Next가 root-level Player에 반영된다.
5. Player가 tab 전환과 feature navigation 중에도 유지된다.
6. MiniPlayer와 expanded Player가 하나의 playback state를 공유한다.
7. 앱 재실행 후 Follow, Queue, 현재 Episode, 재생 위치가 복원된다.
8. UIKit container와 SwiftUI feature view가 RIBsLite의 VC tree 안에서 조합된다.

## 8. Scope

### In Scope

- public Podcast discovery
- Podcast Follow/Unfollow
- Library
- followed Podcast 기반 Latest
- Podcast/Episode search
- Podcast/Episode detail
- audio streaming playback
- Play Next와 Queue 관리
- current playback 및 position 복원
- loading, empty, partial failure, failure 상태
- local persistence

### Out of Scope

- Episode Keep 또는 Saved Episodes
- 유료 Podcast Subscription
- 계정과 cross-device sync
- 명시적 download UI
- guaranteed offline playback
- persistent audio file cache
- private 또는 paid RSS feed
- personalized recommendation
- production analytics

## 9. Success Criteria

Ditto3의 성공 여부는 전환율이나 retention으로 판단하지 않는다. 다음을 만족하면 architecture sample의 목적을 달성한 것으로 본다.

- 위 user flow가 일관된 domain terminology로 동작한다.
- Feature가 복수 진입점에서 재사용된다.
- RIBsLite가 navigation, lifecycle, dependency composition을 명확히 표현한다.
- 공유 domain state가 feature 간에 예측 가능하게 전달된다.
- Player처럼 root에 지속되는 child VC를 RIB tree 안에서 표현할 수 있다.
- viewless Riblet 없이도 필요한 화면 구성을 유지할 수 있다.
