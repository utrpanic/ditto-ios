# PRD: KeepCast

## 1. Executive Summary & Context

**Product Name:** KeepCast

### Terminology

- **Podcast:** 하나의 feed 아래 여러 episode를 제공하는 프로그램 단위
- **Episode:** 사용자가 탐색, keep, 재생하는 개별 콘텐츠 단위

이 문서에서는 같은 개념을 가리키는 별도 도메인 용어를 도입하지 않고 `Podcast -> Episode` 관계를 일관되게 사용한다.

KeepCast는 podcast에 대한 사전 지식이 없는 사용자가 인기 episode를 빠르게 탐색하고, 관심 있는 episode를 keep한 뒤 원할 때 재생할 수 있는 비로그인 episode-first podcast app이다.

기존 podcast 경험은 대체로 특정 podcast 또는 podcaster 중심이다. 이 구조는 이미 좋아하는 podcast가 있거나 특정 host를 아는 사용자에게는 적합하지만, 신규 사용자가 “지금 사람들이 많이 듣는 episode가 무엇인지”를 빠르게 파악하기에는 진입 장벽이 높다.

KeepCast의 초기 제품 가설은 단순하다. 사용자는 계정 생성, 구독 설정, 복잡한 onboarding 없이도 인기 episode를 훑어보고, 나중에 듣고 싶은 episode를 저장하고, 필요할 때 바로 재생할 수 있어야 한다.

이 PRD의 범위는 full podcast platform이 아니다. 초기 버전은 **Explore -> Keep -> Playback** 루프를 검증하는 데 집중한다.

## 2. Goals & Guardrail Metrics

### Goals

1. 비로그인 사용자가 첫 세션에서 episode를 탐색할 수 있게 한다.
2. 사용자가 관심 있는 episode를 keep하여 나중에 재방문할 이유를 만든다.
3. podcast 중심 탐색이 아니라 episode 중심 탐색 경험을 검증한다.
4. public podcast RSS 기반 streaming/playback 가능성을 검증한다.

### Primary Metrics

- **Episode Impression to Keep Rate:** episode 노출 대비 keep 비율
- **First Keep Conversion:** 첫 실행 후 5분 이내 최소 1개 episode를 keep한 사용자 비율
- **Keep to Playback Rate:** keep된 episode 중 실제 재생된 episode 비율
- **Time to First Play:** 앱 실행 후 첫 재생까지 걸린 시간, 목표 p50 60초 이하
- **D1 Return Rate:** keep 경험이 있는 사용자의 다음날 재방문율

### Guardrail Metrics

- **Playback Failure Rate:** 재생 시도 대비 실패율 5% 이하
- **Content Coverage Failure Rate:** episode 후보 중 표시/재생 가능한 상태로 만들지 못한 비율 10% 이하
- **Cold Start to Content Visible:** 앱 실행 후 첫 episode 목록 표시까지 p50 2초 이하, p95 5초 이하
- **Crash-Free Sessions:** 99.5% 이상
- **Storage Usage:** 다운로드/캐시 기능 도입 시 기본 저장소 사용량 500MB 이하로 제한
- **User Friction:** 첫 keep 또는 첫 play 전에 로그인, 권한 요청, 결제 요청을 노출하지 않는다.

## 3. User Stories with Acceptance Criteria

### Story 1: 인기 episode 탐색

사용자는 podcast를 몰라도 앱을 열자마자 인기 episode 목록을 보고 싶다.

**Acceptance Criteria**

- 앱 첫 화면에서 episode list가 표시된다.
- 각 episode row는 최소한 episode title, podcast title, artwork, publish date 또는 relative date, duration이 표시된다.
- podcast가 아니라 episode 단위로 탭 가능해야 한다.
- 첫 화면 진입 시 로그인 요구가 없어야 한다.
- 데이터 로딩 중에는 skeleton 또는 loading state를 표시한다.
- 데이터가 없을 경우 empty state를 표시한다.

### Story 2: episode keep

사용자는 나중에 듣고 싶은 episode를 keep할 수 있다.

**Acceptance Criteria**

- 각 episode row 또는 detail에 keep action이 존재한다.
- keep action은 1 tap으로 완료된다.
- keep 상태는 앱 재실행 후에도 유지된다.
- 이미 keep된 episode는 명확한 selected state를 가진다.
- 같은 episode를 중복 keep하지 않는다.
- keep 해제도 가능해야 한다.

### Story 3: keep한 episode 보기

사용자는 keep한 episode만 모아서 볼 수 있다.

**Acceptance Criteria**

- 별도 Keep list 화면 또는 tab이 존재한다.
- keep list는 최신 keep 순으로 정렬된다.
- keep list가 비어 있으면 empty state를 표시한다.
- keep list의 episode는 바로 재생 가능해야 한다.

### Story 4: episode streaming playback

사용자는 keep 여부와 관계없이 episode를 바로 재생할 수 있다.

**Acceptance Criteria**

- episode가 재생 가능한 상태인 경우 play action을 제공한다.
- play action 후 p50 2초 이하로 playback이 시작된다.
- buffering, playing, paused, failed 상태가 UI에 반영된다.
- 재생 실패 시 retry 또는 fallback message를 제공한다.
- 앱은 private feed, paid feed, DRM-protected content 재생을 지원하지 않아도 된다.

### Story 5: episode detail

사용자는 episode를 선택해 내용을 확인한 뒤 keep 또는 play 여부를 결정할 수 있다.

**Acceptance Criteria**

- detail 화면은 episode title, podcast title, artwork, description, publish date, duration, keep button, play button을 포함한다.
- description이 HTML 또는 긴 텍스트일 경우 readable text로 표시한다.
- description이 없으면 UI가 깨지지 않고 fallback copy를 표시한다.

## 4. Functional & Data Requirements

### Product Rules

- 첫 화면은 podcast가 아니라 episode 중심으로 구성한다.
- 사용자는 로그인 없이 episode를 탐색, keep, 재생할 수 있어야 한다.
- keep한 episode는 앱을 다시 열어도 유지되어야 한다.
- 같은 episode는 중복 keep되지 않아야 한다.
- 재생 가능한 episode만 primary playback action을 제공한다.
- duration, description, artwork처럼 원본 데이터가 없는 정보는 임의로 만들어내지 않는다.
- MVP는 cross-device sync를 제공하지 않는다.
- 제품 내 표현은 “episode-first discovery”를 중심으로 하되, 데이터 한계상 실제 ranking이 “인기 podcast 기반 episode”일 수 있음을 내부적으로 인지한다.

### MoSCoW Prioritization

**Must Have**

- 비로그인 episode explore
- episode row UI
- keep/unkeep
- keep 상태 유지
- streaming playback
- loading, empty, error state

**Should Have**

- episode detail
- keep list
- playback mini player
- retry action
- search by keyword
- partial content failure fallback

**Could Have**

- episode download for offline playback
- category filter
- region selector
- basic analytics event logging
- playback speed control
- listened progress
- background audio controls

**Won't Have for MVP**

- user account
- paid podcast support
- private RSS feed support
- creator/podcaster dashboard
- personalized recommendation model
- cross-device sync
- social sharing feed

## 5. User Experience & Edge Cases

### Happy Path

1. 사용자가 앱을 실행한다.
2. Explore 화면에서 인기 episode 목록을 본다.
3. 관심 있는 episode를 keep한다.
4. episode detail을 열거나 row에서 바로 재생한다.
5. 나중에 Keep list로 돌아와 저장한 episode를 재생한다.

### Edge Cases

- **Empty State:** 인기 podcast 또는 episode가 없으면 “표시할 episode가 없음” 상태를 보여주고 retry를 제공한다.
- **Loading Failure:** 콘텐츠를 불러오지 못하면 error state와 retry action을 제공한다.
- **Partial Content Failure:** 일부 source에서 episode를 가져오지 못하더라도 가능한 episode를 우선 보여준다.
- **Unplayable Episode:** 재생할 수 없는 episode는 play button을 비활성화하거나 숨긴다.
- **Invalid Artwork URL:** placeholder artwork를 표시한다.
- **Missing Duration:** duration 영역을 숨기거나 fallback text를 표시한다. 임의 값을 표시하지 않는다.
- **Slow Network:** loading state를 유지하고 p95 5초 초과 시 “still loading” 상태를 표시한다.
- **Playback Failure:** user-facing error와 retry를 제공한다.
- **No Login:** keep data는 현재 기기에만 유지된다. 삭제/기기 변경 시 복구되지 않는다.
- **Permissions:** MVP streaming은 사전 권한 요청 없이 동작해야 한다.

## 6. Product Constraints & Data Needs

### Data Requirements

Each episode must provide enough information to support list display, detail display, keep/unkeep, and streaming playback.

Required episode attributes:

- episode title
- podcast title
- artwork when available
- audio URL for playback
- publish date when available
- duration when available
- description when available
- stable identifier for keep/unkeep

Keep data must persist on the current device without requiring login. Cross-device restore is not required for MVP.

### Data Sources

- Apple RSS Marketing Tools API
- iTunes Search / Lookup API
- Public Podcast RSS Feed

These sources should be treated as product inputs, not guaranteed complete records. Missing metadata is expected and must not block the whole experience.

### Performance Requirements

- Explore 화면은 일반적인 네트워크 환경에서 2초 안에 첫 episode 목록을 보여주는 것을 목표로 한다.
- 네트워크가 느린 경우에도 사용자는 5초 안에 콘텐츠, loading 상태, 또는 error 상태 중 하나를 명확히 봐야 한다.
- Play 버튼을 누르면 가능한 경우 2초 안에 재생이 시작되어야 한다.
- Keep/unkeep 버튼은 누르는 즉시 시각적으로 반응해야 한다.

### Product Constraints

- MVP는 계정 생성, 로그인, 결제, 구독 관리를 포함하지 않는다.
- MVP는 공개적으로 접근 가능한 podcast content만 대상으로 한다.
- MVP는 다운로드보다 streaming playback 검증을 우선한다.
- 현재 `TopPodcasts` 구현은 product spike로 보고, 최종 UX는 KeepCast 요구사항을 기준으로 재정의한다.

## 7. Go-To-Market & Learning Plan

### Initial Onboarding Strategy

- MVP는 onboarding screen을 두지 않는다.
- 첫 화면에서 바로 episode list를 보여준다.
- 첫 keep 이후에만 lightweight confirmation을 보여준다.
- 로그인 CTA는 MVP에서 제공하지 않는다.

### Learning Signals

- 사용자가 첫 세션에서 episode를 keep하는가?
- 사용자가 keep한 episode를 다시 찾아와 재생하는가?
- 사용자가 podcast 탐색 없이도 episode를 선택하는가?
- 검색 기능이 episode discovery를 보완하는가?
- 재생 실패나 데이터 누락이 탐색 흐름을 방해하는가?

### Optional Analytics

이 프로젝트는 실제 publish 목적이 아니므로 production analytics는 MVP 필수 범위가 아니다. 다만 구현 학습을 위해 lightweight event logging을 둘 수 있다. 구체 event schema는 TRD에서 정의한다.

## 8. Open Questions & Risks

### Open Questions

1. Explore ranking을 “popular podcast의 latest episodes”로 만들 것인가, 아니면 “popular episodes”에 가까운 별도 ranking logic을 만들 것인가?
2. Apple RSS Marketing Tools API만으로 episode-level trend를 충분히 만들 수 있는가?
3. MVP에서 download를 포함할 것인가, 아니면 streaming + keep까지만 검증할 것인가?
4. Keep list의 정렬 기준은 keep time인가, publish date인가?
5. episode detail을 MVP에 반드시 포함할 것인가, 아니면 row expansion으로 대체할 것인가?
6. 검색은 episode title 중심으로 할 것인가, podcast title까지 포함할 것인가?
7. analytics는 학습용 local logging만 둘 것인가, 완전히 제외할 것인가?

### Risks

- Apple RSS top podcast API는 podcast 중심이므로 episode-first product와 데이터 모델 간 mismatch가 있다.
- public podcast metadata 품질이 균일하지 않아 duration, artwork, description, playback source가 누락될 수 있다.
- 일부 episode는 안정적으로 재생되지 않을 수 있다.
- offline download는 저작권, publisher policy, storage management 이슈를 만든다.
- local-only keep은 단순하지만 기기 변경/삭제 시 데이터 복구가 불가능하다.
- episode trend 품질이 낮으면 product positioning이 “인기 episode 탐색”이 아니라 “인기 podcast의 최신 episode 나열”로 약해질 수 있다.
