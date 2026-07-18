# DEV NOTES — 이어서 작업하기 위한 핸드오프

> 다른 컴퓨터에서 `git clone` 후 이 문서만 읽으면 이어서 작업할 수 있도록 정리한 개발 노트입니다.
> (사용자용 소개는 [`README.md`](README.md), 디자인 명세는 [`DESIGN.md`](DESIGN.md), 리뷰 마크다운 양식은 [`REVIEW-FORMAT.md`](REVIEW-FORMAT.md), 출시는 [`PaperDaily/RELEASE.md`](PaperDaily/RELEASE.md).)

## 1. 이게 뭔가
`논문 데일리 · Daily Papers` — 대학원생/연구자용 **매일 논문 추천 iOS 앱**. 디자인 핸드오프를 **네이티브 SwiftUI**로 재구현.
화면: 스플래시 → 온보딩 → 추천 피드 → 논문 상세(원문/번역 토글) → 상세 리뷰(에이전트 리뷰 뷰어) → 라이브러리 → 주간 요약 → 설정. **한국어/영어 UI 전환** 지원.

- 플랫폼: **iOS 17+**, SwiftUI. 외부 패키지(SPM) 2개: **MarkdownUI**(swift-markdown-ui 2.4.x, 리뷰 마크다운 렌더) + **SwiftMath**(1.7.x, 수식 렌더) — 네이티브 리뷰 리더 전용.
- Xcode 프로젝트: `PaperDaily/PaperDaily.xcodeproj` (Xcode 16+ 파일시스템 동기화 그룹 방식).

## 2. 새 맥에서 개발 환경 세팅
1. **정식 Xcode 필요** (Command Line Tools만으론 시뮬레이터 불가). App Store에서 Xcode 설치.
2. `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` → `sudo xcodebuild -license accept`
3. **iOS 플랫폼/시뮬레이터 런타임 다운로드**: `xcodebuild -downloadPlatform iOS` (Xcode 26은 iOS 미포함 출고, ~8GB).
4. ⚠️ **시뮬레이터 함정** (겪었음):
   - CoreSimulator는 전역 `xcode-select` 디렉터리만 따름 — `DEVELOPER_DIR` 환경변수로는 시뮬레이터가 안 잡힘.
   - **CoreSimulatorService를 `pkill` 하지 말 것** — 크립텍스 런타임 마운트가 고아가 됨. 복구: `xcrun simctl runtime unmount <id>`.
   - **"중복" 런타임 이미지를 `simctl runtime delete` 하지 말 것** — 공유 백업 자산까지 지워져 런타임 손상. 손상 시: `simctl runtime delete all` 후 재다운로드.

## 3. 빌드 · 실행 · 스크린샷
```bash
# 빌드 (시뮬레이터)
xcodebuild -project PaperDaily/PaperDaily.xcodeproj -scheme PaperDaily -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/pd_build \
  CODE_SIGNING_ALLOWED=NO build

# 헤드리스 실행 + 스크린샷
xcrun simctl boot "iPhone 17"
xcrun simctl install booted /tmp/pd_build/Build/Products/Debug-iphonesimulator/PaperDaily.app
xcrun simctl launch booted com.paperdaily.app
sleep 10   # SwiftUI 첫 프레임이 느림 — 10초쯤 기다린 뒤 캡처 (그전엔 검은 화면)
xcrun simctl io booted screenshot out.png
```
- 릴리스 아카이브 검증: `xcodebuild archive ... -configuration Release ... CODE_SIGNING_ALLOWED=NO`.
- 코드만 빠르게 검증(시뮬 없이): `swiftc -parse *.swift`; macOS SDK로 `-typecheck` (단, `.toolbar(.hidden,for:.navigationBar)`·`.navigationBarBackButtonHidden` 등 iOS 전용 모디파이어는 제거 후).

### 테스트/미리보기 런치 훅 (env `SIMCTL_CHILD_<NAME>` 로 전달, 프로덕션 무동작)
| 키 | 효과 |
|---|---|
| `PD_ONBOARDED=1` | 온보딩 건너뛰고 메인 탭 |
| `PD_TAB=home\|library\|stats\|settings` | 초기 탭 |
| `PD_DETAIL=1` | 첫 논문 상세로 바로 진입 |
| `PD_TRANSLATED=1` | 상세를 번역본 상태로 시작 |
| `PD_LANG=ko\|en` | UI 언어 강제 |
| `PD_FEED_URL=<url>` | 피드 URL 강제 (`file://` / `http(s)://`) |
| `PD_HOLD_SPLASH=1` | 스플래시 유지 (캡처용) |
| `PD_SEED_SAVED=1` | 저장됨 탭에 논문 2편 시드 |
| `PD_LIB_TAB=toRead\|saved\|done` | 라이브러리 초기 탭 |
| `PD_REVIEW_SAMPLE=1` | 첫 피드 논문에 번들 `SampleReview.md`를 붙여 네이티브 리뷰 리더 진입 가능 |
| `PD_REVIEW=1` | 첫 논문 상세를 거쳐 **네이티브 리뷰 리더로 바로 진입** (샘플 마크다운 자동 부착) |
| `PD_REVIEW_SEC=<n>` | 리더 로드 후 섹션 n(0-기준)으로 자동 스크롤 — 상태 B(리딩 헤더/본문) 캡처용 |
| `PD_INTERESTS_OVERRIDE=VLN[,…]` | 관심 분야 강제 (부팅 중 `spawn defaults write`는 cfprefsd 캐시 레이스로 불신뢰 — 이 훅 사용) |
| `PD_STATS_DETAIL=1` | 통계 탭의 하이라이트 논문 상세를 자동 push (통계 네비게이션 검증용) |
> ⚠️ `simctl`은 한 셸 스크립트 안에서 연속 launch 시 `SIMCTL_CHILD_*`를 **첫 launch에만** 적용. 화면별로 **개별 명령**(각각 terminate→uninstall→install→launch)으로 캡처할 것. `-KEY value` 런치 인자는 앱에 안 닿음(simctl이 먹음).

## 4. 코드 구조 (`PaperDaily/PaperDaily/`)
- `PaperDailyApp.swift` — `@main`, `RootView`(스플래시→온보딩/메인), 폰트 등록, 스플래시 동안 밝은 상태바.
- `AppState.swift` — 단일 스토어. `lang`·`frequency`·`interests`·`onboarded`(모두 영속, 4-4)·`savedIDs`/`readIDs`/`toReadItems`·피드 로딩·라이브러리 헬퍼·런치 훅 파싱. **관심 분야 ↔ 피드 연동(4-1)**: 온보딩 칩은 실피드가 있으면 실제 카테고리(VLN/Planner), 피드는 `interests`로 필터링(분류 체계가 안 겹치면 필터 해제 + 실카테고리로 자동 정렬).
- `Localization.swift` — `AppLanguage`, `Strings`(ko/en 사전), `Topics`/`Tags`(한글 canonical→영문) 매핑, `FeedHeaderText`, `LocalizedString`.
- `Models.swift` — `Frequency`, `Paper`, `LibraryItem`, 주간 통계 타입.
- `SampleData.swift` — 피드 3편 + 라이브러리 전용 6편 + `catalog`(전체) + 주간 통계.
- `Config.swift` — 피드 URL (`defaultFeedURLString` 비면 샘플).
- `PaperService.swift` — 원격 `daily.json` fetch + DTO 매핑 + 디스크 캐시 + 샘플 폴백.
- `Theme.swift` — `Palette`, `AppFont`(serif/sans/mono/**script**+`registerBundledFonts`), 그림자.
- `Components.swift` — `FlowLayout`, 칩/태그/`MatchBadge`/`ProgressTrack`/버튼/`AppTabBar`(점 슬라이드).
- `MainTabView.swift` — 커스텀 탭 컨테이너(4탭 상시 유지 + 크로스페이드, 영속 탭바, 상세 push 시 탭바 숨김).
- `OnboardingView.swift` — `LanguageSegment`·`FrequencySegment`·`InterestChip`.
- `FeedView.swift` · `PaperDetailView.swift`(진입 탭에 맞는 뒤로가기 라벨) · `LibraryView.swift` · `SettingsView.swift`.
- `WeeklySummaryView.swift` — **주간 요약은 전부 실제 상태에서 파생**: 읽음/저장 개수는 `readIDs`/`savedIDs`, 주제 분포는 저장·읽은 논문의 카테고리 비율(상위 4 + 기타), 하이라이트는 그중 리뷰가 가장 긴 논문(탭 → 상세), 연속 일수는 읽음 처리한 날짜(`PD_READ_DAYS`) 기반. 데이터가 없으면 빈 상태 문구.
- `ReviewReaderView.swift` — **네이티브 리뷰 리더 (화면 6/7)**: `paper.reviewMarkdownURL`(전처리 마크다운)을 MarkdownUI+SwiftMath로 렌더. 출판 정보/목차 카드, 리딩 헤더(현재 섹션+진행률), 섹션 네비, 수식(파싱 실패 시 serif italic 폴백), 다크 ASCII 다이어그램, 읽기 위치 저장(UserDefaults). 피드에 `reviewMarkdownURL` 필드가 생기면 자동으로 이 리더가 우선됨. 테스트: `PD_REVIEW_SAMPLE=1` + 번들 `SampleReview.md`.
- `ReviewView.swift` — (과도기) WKWebView 리뷰 리더. `reviewMarkdownURL`이 없고 `reviewURL`만 있을 때 사용. `app=1`을 붙여 로드하면 페이지가 자체 상단 바를 숨김. 웹 리뷰 페이지 디자인은 맥미니 `~/repos/paper-review/scripts/paperdaily-feed/generate.js`가 생성 — 콘텐츠 계약은 [`REVIEW-FORMAT.md`](REVIEW-FORMAT.md).
- `SplashView.swift` — 테라코타 스플래시(Dancing Script 워드마크 + 로딩바).
- `SwipeBack.swift` — 백버튼 숨긴 상태에서 엣지 스와이프 뒤로가기 활성화(`UINavigationController` 확장).
- `DancingScript.ttf`(번들 폰트) + `DancingScript-OFL.txt`(라이선스). `Assets.xcassets`(AppIcon·AccentColor).

### 로컬라이제이션 추가 방법
새 UI 문구 → `Localization.swift`의 `Strings` 구조체 + `ko`/`en` 인스턴스에 필드 추가 → 뷰에서 `app.strings.<key>`. 논문 본문(제목/초록)은 **원문 고정**(번역 토글로만 한국어), 태그/주제는 `Tags`/`Topics` 매핑, canonical 값은 한글 유지.

## 5. 맥미니 피드 연동 (다음 단계, 미완)
설계: 항상 켜진 맥미니가 매일 논문을 찾아 [`PaperDaily/Backend/daily.schema.md`](PaperDaily/Backend/daily.schema.md) 형식의 `daily.json`을 HTTPS URL에 게시 → 앱이 fetch(실패 시 캐시→샘플 폴백). 예시: [`daily.example.json`](PaperDaily/Backend/daily.example.json).
- **연결하려면**: `Config.swift`의 `defaultFeedURLString`에 URL 한 줄. (테스트는 `PD_FEED_URL`.)
- 검증 완료: 실제 코드로 예시 JSON 디코드 OK, 시뮬레이터 file:// end-to-end OK.
- 맥미니의 현재 출력 형식을 알면 → JSON 어댑터 스크립트 작성 예정.

## 6. 출시 상태
- **라이선스: © 2026 romaster93 · All Rights Reserved** ([`LICENSE`](LICENSE)). Dancing Script는 OFL 별도.
- 앱 아이콘 완료, 릴리스 아카이브 빌드 통과, 6.9" 스크린샷·메타데이터 준비됨([`PaperDaily/AppStore/`](PaperDaily/AppStore)).
- **미제출**. TestFlight/App Store 절차는 [`PaperDaily/RELEASE.md`](PaperDaily/RELEASE.md). 실제 심사 통과엔 맥미니 실데이터 + 개인정보 처리방침 필요.
- 실기기 무료 테스트: Xcode Personal Team 서명 + iOS 개발자 모드 + 인증서 신뢰(7일 만료).

## 7. Git
- 원격: `https://github.com/romaster93/dailypaper` (main). PRIVATE→PUBLIC 전환됨.
- **인증(새 맥)**: `brew install gh` → `gh auth login` (GitHub.com→HTTPS→browser).
- **대용량 푸시 오류(HTTP 400) 방지 설정** (스크린샷 등 커밋 때문에 필요):
  ```bash
  git config http.postBuffer 524288000
  git config http.version HTTP/1.1
  ```
- `.gitignore`: 빌드 산출물·DerivedData·`.omc/` 제외. 이 문서·스크린샷·폰트는 커밋됨.

## 8. 다음 작업 / TODO
- [ ] 맥미니 `daily.json` 연동 (Config URL 설정 + 어댑터).
- [ ] (보류) 라이브러리 스와이프-삭제 — 현재는 **롱프레스 → 삭제** 및 상세의 "저장됨" 재탭으로 해제. (List 리팩터 필요.)
- [ ] 공개 출시용 실백엔드(arXiv/번역 API) + 개인정보 처리방침.
- [ ] (선택) 프로덕션 빌드에서 `PD_*` 테스트 훅 정리.
- [ ] (선택) OS 런치 스크린 배경 테라코타로(현재 잠깐 흰 플래시).
