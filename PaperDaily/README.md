# 논문 데일리 (Daily Papers) — iOS 앱

디자인 핸드오프(`../DESIGN.md`, `../design-prototype.html`)를 **네이티브 SwiftUI**로 재구현한 iOS 앱입니다. High-fidelity 시안의 색상·타이포그래피·간격·인터랙션을 디자인 토큰 그대로 옮겼습니다.

## 실행 방법
1. Xcode 16 이상에서 `PaperDaily.xcodeproj` 를 엽니다.
2. 상단에서 iPhone 시뮬레이터(예: iPhone 15/16)를 선택합니다.
3. **⌘R** 로 빌드·실행합니다.

> 배포 타깃: **iOS 17.0+**. 별도 의존성/패키지 없음(순수 SwiftUI). 서명 팀 없이 시뮬레이터에서 바로 실행됩니다. 실기기 실행 시 Signing & Capabilities에서 팀만 지정하세요.

## 검증 (Verified on simulator)
Xcode 26.6 / iPhone 17 (iOS 26.5) 시뮬레이터에서 **빌드·실행 확인 완료**. 6개 화면 실제 렌더 스크린샷은 [`screenshots/`](screenshots/)에 있습니다 — 온보딩, 피드, 상세(원문/번역본), 라이브러리, 주간 요약. 번역 토글로 제목·저자·초록·플래그·라벨·버튼이 동시에 스왑되는 것까지 확인했습니다.

CLI 빌드:
```bash
xcodebuild -project PaperDaily/PaperDaily.xcodeproj -scheme PaperDaily \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## 테스트/미리보기 진입 훅
`AppState.init`은 특정 화면으로 바로 진입하는 런치 훅을 지원합니다(프로덕션에선 값 미설정 시 **무동작**). UI 테스트·스크린샷 자동화용:

| 키 | 효과 |
|---|---|
| `PD_ONBOARDED=1` | 온보딩 건너뛰고 메인 탭 진입 |
| `PD_TAB=home\|library\|stats\|settings` | 초기 탭 지정 |
| `PD_DETAIL=1` | 첫 논문 상세로 바로 진입 |
| `PD_TRANSLATED=1` | 상세를 번역본 상태로 시작 |

```bash
# 예: 번역본 상세 화면으로 바로 실행
env SIMCTL_CHILD_PD_DETAIL=1 SIMCTL_CHILD_PD_TRANSLATED=1 \
  xcrun simctl launch booted com.paperdaily.app
```
> ⚠️ `simctl`은 배치 스크립트에서 연속 실행 시 `SIMCTL_CHILD_*`를 첫 실행에만 적용하는 경우가 있어, 화면별로 **개별 명령**(각각 uninstall→install→launch)으로 캡처하는 것이 안정적입니다.

## 화면 구성 (핸드오프 5화면 + 설정)
- **온보딩** (`OnboardingView`) — 추천 주기 세그먼트(매일/매주/매달) + 관심 분야 칩. 기본 선택: 자연어처리·HCI·생성모델.
- **추천 피드** (`FeedView`) — 주기에 연동되는 헤더, 가로 필터 칩, 논문 카드. 카드 탭 → 상세.
- **논문 상세** (`PaperDetailView`) — **번역 토글**(제목·저자·초록·언어 플래그·라벨·버튼이 동시에 원문↔한국어로 즉시 스왑). 푸시 뷰(탭바 없음).
- **라이브러리** (`LibraryView`) — 읽을 목록/저장됨/완료 탭 전환, 진행 바.
- **주간 요약** (`WeeklySummaryView`) — 통계 카드 3개, 주제 분포 막대, 하이라이트.
- **설정** (`SettingsView`) — 주기·관심 분야 재조정(핸드오프 미명세, 온브랜드 최소 구현).

## 폰트 대체
핸드오프의 Google Fonts는 지침("유사 시스템 폰트로 대체")에 따라 시스템 폰트로 매핑했습니다.
- Newsreader(serif) → `.system(design: .serif)` (New York)
- Public Sans(sans) → `.system(design: .default)` (SF)
- JetBrains Mono(mono) → `.system(design: .monospaced)` (SF Mono)

번들 폰트로 픽셀 단위까지 맞추려면 `.ttf`를 타깃에 추가하고 `AppFont`(`Theme.swift`)의 반환을 커스텀 폰트로 바꾸면 됩니다.

## 코드 구성
| 파일 | 역할 |
|---|---|
| `Theme.swift` | 색상/폰트/그림자 등 디자인 토큰 |
| `Models.swift` | `Frequency`, `Paper`, `LibraryItem`, 통계 모델 |
| `SampleData.swift` | 프로토타입과 동일한 샘플 콘텐츠(원문+번역) |
| `AppState.swift` | 크로스 스크린 상태(`ObservableObject`) |
| `Components.swift` | `FlowLayout`, 칩/태그/배지/진행바/탭바 |
| `MainTabView.swift` | 커스텀 탭 컨테이너 + 네비게이션 |
| `*View.swift` | 5개 화면 + 설정 |

## 데이터 참고
현재 콘텐츠는 번들 픽스처입니다. 실제 앱에서는 핸드오프 명세대로 논문 소스 API(arXiv·Semantic Scholar), 번역 API(온디맨드), 매칭/스코어링, 계정·동기화로 대체하세요.
