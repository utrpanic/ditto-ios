# TODO

완료한 항목은 제목 끝에 `✅`를 붙인다.

1. PRD/TRD를 확정된 Podcast, Follow, Latest, Queue, Player 개념으로 정리한다. ✅
2. Feature와 Repository 명칭 및 `docs`, `scripts` 디렉터리를 정리한다. ✅
3. 기존 Episode Keep 구현을 제거한다. ✅
4. Following Core Layer를 구현한다. ✅
   - `FollowedPodcast` entity를 추가한다.
   - `FollowingRepository`가 전체 Podcast snapshot과 `followedAt`을 저장하게 한다.
   - versioned JSON persistence와 change stream을 구현한다.
   - follow, unfollow, idempotency, persistence를 테스트한다.
5. Podcast Follow UI를 구현한다.
   - `FollowingRepository`를 Podcast feature에 주입한다.
   - Follow/Unfollow action과 상태를 추가한다.
   - optimistic update와 failure rollback을 구현한다.
   - 모든 Podcast 진입점에서 같은 Follow 상태를 표시한다.
6. Library Feature를 구현한다.
   - Follow한 Podcast 목록과 empty state를 표시한다.
   - Podcast feature로 routing한다.
   - Following change stream을 반영한다.
7. Latest Feature를 구현한다.
   - Follow한 Podcast의 Episode를 병렬로 조회한다.
   - EpisodeID로 중복을 제거하고 `publishedAt` 내림차순으로 정렬한다.
   - 최대 20개를 표시한다.
   - partial failure와 전체 failure를 구분한다.
   - Episode feature로 routing한다.
8. Playback Foundation을 구현한다.
   - background playback과 잠금 화면 제어의 범위를 확정한다.
   - `PlaybackControlling`과 `PlaybackState`를 정의한다.
   - AVPlayer 기반 Platform 구현을 추가한다.
   - play, pause, seek, 앞뒤 건너뛰기와 상태 전환을 테스트한다.
9. Persistent Player Feature를 구현한다.
   - Player를 Main의 root-level child Riblet으로 연결한다.
   - 모든 tab 위에 MiniPlayer를 배치한다.
   - expanded Player를 구현한다.
   - tab과 navigation 전환 중 Player가 유지되는지 검증한다.
10. Episode Playback을 연결한다.
    - Episode 상세에 Play action을 추가한다.
    - Podcast, Latest, Search 등 모든 진입점에서 같은 playback flow를 사용한다.
11. Queue Core Layer를 구현한다.
    - `QueueItem`과 `PlaybackQueueRepository`를 추가한다.
    - Play Next, 중복 제거, 재정렬, 개별 제거, 전체 제거를 구현한다.
    - Queue persistence와 change stream을 테스트한다.
12. Queue UI와 Play Next를 연결한다.
    - Episode 상세에 Play Next action을 추가한다.
    - expanded Player 안에 Queue를 표시한다.
    - Queue 선택, 재정렬, 제거를 연결한다.
13. Resume Playback을 구현한다.
    - `PlaybackSessionRepository`를 추가한다.
    - 현재 Episode snapshot과 position을 저장한다.
    - 앱 재실행 시 paused MiniPlayer를 복원한다.
    - 재생 시 저장된 위치로 seek한다.
14. Architecture 시나리오를 검증한다.
    - Podcast feature의 Discover, Search, Library 진입을 검증한다.
    - Episode feature의 Podcast, Latest, Search, Queue 진입을 검증한다.
    - Follow 변경이 Library와 Latest에 반영되는지 검증한다.
    - Play Next가 persistent Player와 Queue에 반영되는지 검증한다.
    - Interactor activation/deactivation과 stream observation 수명을 검증한다.
