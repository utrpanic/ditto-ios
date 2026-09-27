# Ditto3

## Requirements

- Xcode 26

## Project setup

- [Install `mise` CLI](https://mise.jdx.dev/getting-started.html#installing-mise-cli).
- Run `./setup.sh` or `./setup.sh --no-open`.
- Run `./build.sh` or pass extra `xcodebuild` arguments such as `./build.sh -scheme Feature`.

## RIBsLite

Ditto3는 RIBs의 역할 분리를 유지하면서 기능의 소유권을 VC 중심으로 바꾸고, Presentable·PresentableListener를 Store·Action으로 대체한 RIBsLite의 샘플 앱이다. 아래는 원본 RIBs에 익숙한 독자를 위한 변경점과 구현 규약이다.

### Router 트리 대신 VC 트리

출발점은 Edge swipe back처럼 UIKit이 시작하는 전환까지 Router 트리와 동기화해야 하는 부담이었다. 화면과 기능의 수명이 일치한다면 UIKit의 소유 관계를 그대로 사용할 수 있다고 보았다.

VC → Interactor → Router 순서로 소유하며, Router는 VC를 약하게 참조한다. 목적지의 소유는 navigation stack이나 child containment에 맡긴다. Router가 자식 VC를 보관하는 경우에도 약한 참조를 사용한다.

별도 Router 트리의 attach/detach 동기화를 없앤 대신, Viewless Riblet과 UI에 독립적인 업무 트리·활성 범위 관리는 의도적으로 포기했다. 화면 독립적인 업무는 Service나 Repository 등 앱에 맞는 별도 구현으로 구성한다.

### Interactor–VC 관계와 표현 계약

Interactor가 Presentable을 참조하는 관계를 뒤집어, VC가 Interactor를 소유한다. Interactor는 VC나 Presenter를 직접 참조하지 않고 StateStore를 변경한다. VC는 기능의 수명을 소유하면서 상태 전달과 입력 연결을 담당한다.

| 방향 | 원본 RIBs의 계약 | RIBsLite의 대체 방식 |
| --- | --- | --- |
| Interactor → UI | Presentable 메서드 호출 | StateStore 변경과 상태 관찰 |
| UI → Interactor | PresentableListener 메서드 호출 | `sendAction(Action)` |

표현 계약은 상태와 Action으로 명시한다. 일반 화면의 VC는 StateReader를 통해 SwiftUI View에 State 값과 Action 전달 경로를 제공한다. View에는 Store를 넘기지 않으며, VC가 상태를 쓰지 않는 것은 컨벤션이다. UIKit 기반 Main은 상태를 직접 구독한다. SwiftUI 호스팅 자체와 구분되는 이 계약 변경은 RIBsLite의 핵심 선택이다. 기능 간 통신에 사용하는 Listener는 그대로 유지한다.

### 구현 규약

1. **초기화:** 별도의 Router attach가 없으므로, 이에 대응하는 활성화 시점은 VC가 UIKit 계층에 부착되는 시점이다. 다만 이 시점을 각 전환 경로에서 처리하는 대신, Builder가 Router·Listener 연결을 마친 뒤 `interactor.activate()`를 한 번 호출하도록 단순화했다. 따라서 `build()`는 생성과 시작을 포함하며, 초기 작업은 VC 부착 전에 시작할 수 있다. `didBecomeActive()`에는 부모나 화면 표시 여부에 의존하지 않는 초기 작업을 둔다. 공통 활성 상태나 deactivate 처리는 없고, 작업의 종료·취소는 Feature에서 관리한다.
2. **VC 해제 후 라우팅:** Router는 목적지를 build하기 전에 VC를 `guard`로 확보한다. 표시할 VC가 사라진 뒤 목적지의 생성과 활성화만 실행되는 것을 막는다.

## Ditto3의 샘플 구현

다음은 RIBsLite의 필수 구성이나 규약이 아니라 Ditto3가 선택한 구현이다.

1. **딥링크:** Ditto3는 `DeepLinkRouter`가 목적지를 구성하고 `MainNavigation`을 통해 탭 선택과 push를 요청하도록 구현했다. 이는 앱에 필요한 딥링크 처리를 별도 객체로 구성한 선택이며, 두 타입은 RIBsLite 아키텍처의 일부가 아니다.
2. **Player:** Main에 상주하며, 활성화 시 관찰을 시작해 세션 복원·저장과 다음 항목 재생을 담당한다. 다른 기능은 공유 `PlaybackControlling`과 Repository로 재생 상태·세션·대기열에 접근한다. Player UI의 제거·교체와 재생 업무의 수명 분리는 이 샘플에서 다루지 않는다.

## Ditto3의 DI 구성: Composition Root

RIBsLite와 별개로, Ditto3는 각 Feature의 Dependency를 `AppComponent`에서 조립한다. leaf Riblet에 의존성을 추가할 때 전달만 담당하는 모든 ancestor를 수정하는 대신, 해당 Feature와 Composition Root를 변경한다. 그 대가로 중앙 조립부가 여러 Feature의 의존성을 알게 된다.

이 방식은 원본 RIBs에도 적용할 수 있다. 조립 위치와 객체의 수명 범위는 별개의 선택이며, 현재 샘플의 주요 Repository와 재생 엔진은 AppComponent 범위에서 공유한다.

## 구현 참고

1. [RIBsLite](Architecture/RIBsLite) · [Discover](Feature/Discover/Sources)
2. [Main](Feature/Main/Sources) · [Player](Feature/Player/Sources)
3. [AppComponent](App/Sources/AppComponent.swift) · [상세 구현 명세](docs/TRD.md)
