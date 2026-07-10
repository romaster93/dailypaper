# 출시 가이드 — 논문 데일리 (App Store)

이 문서는 App Store 출시까지 남은 단계를 정리합니다. **굵게 표시된 단계는 사용자님의 Apple 계정이 필요**해서 제가 대신 수행할 수 없습니다.

---

## ⚠️ 먼저: 지금 상태로는 심사 통과가 어렵습니다

현재 앱은 디자인 핸드오프를 재현한 **목업/픽스처 데이터**로 동작합니다(고정된 3편의 논문, 하드코딩된 번역·통계, 백엔드 없음). Apple 심사 기준상 다음이 걸립니다:

- **Guideline 2.1 (App Completeness)** / **4.2 (Minimum Functionality)** — 플레이스홀더·데모 수준 콘텐츠는 반려됩니다.
- **5.1.1 (개인정보 처리방침)** — 제출에 개인정보 처리방침 URL이 **필수**입니다.

### 실제 출시를 하려면 필요한 것 (기능 갭)
1. **논문 소스 연동** — arXiv / Semantic Scholar API로 실제 논문 페칭·검색.
2. **번역 API** — 온디맨드 번역(현재는 하드코딩) + 로딩/실패 처리.
3. **추천/매칭 로직** — 관심 분야 기반 스코어링.
4. **계정·동기화**(선택) — 저장/진행 상태 유지.
5. **개인정보 처리방침 URL**, **지원 URL**.
6. 디버그 런치 훅(`PD_*`)은 런치 인자 없이는 동작 안 하므로 심사에 영향 없음(제거는 선택).

> 요약: **UI/UX 프로토타입으로는 완성**됐고 TestFlight 내부 배포는 가능하지만, **공개 App Store 출시는 위 백엔드 작업 후** 진행하는 것을 권장합니다.

---

## ✅ 이미 준비된 것 (제가 완료)
- 릴리스 아카이브 빌드 검증 통과 (`ARCHIVE SUCCEEDED`, 버전 1.0(1), iOS 17.0+).
- 앱 아이콘(1024px) 적용.
- App Store 규격(6.9") 스크린샷 → [`AppStore/screenshots-6.9/`](AppStore/screenshots-6.9/).
- 스토어 등록 문구(한/영) → [`AppStore/metadata.md`](AppStore/metadata.md).

---

## 1. **Apple Developer Program 등록** (사용자)
- https://developer.apple.com/programs/ 에서 연 **$99** 등록 (개인 또는 조직).
- 승인까지 보통 24~48시간.

## 2. **번들 ID 등록** (사용자)
- App Store Connect → Certificates, Identifiers & Profiles → Identifiers → **+** → App IDs.
- 현재 프로젝트는 `com.paperdaily.app`을 쓰지만, 고유해야 하므로 실제로는 **본인 소유 도메인 역순**(예 `com.<yourname>.paperdaily`)을 권장합니다. 바꾸려면 Xcode의 Target → Signing & Capabilities → Bundle Identifier를 수정하세요.

## 3. **App Store Connect 앱 레코드 생성** (사용자)
- https://appstoreconnect.apple.com → 앱 → **+ 새로운 앱**.
- 플랫폼 iOS, 이름 `논문 데일리`, 기본 언어 한국어, 번들 ID 선택, SKU 입력.
- [`AppStore/metadata.md`](AppStore/metadata.md)의 부제·설명·키워드·프로모션 텍스트를 붙여넣기.
- 스크린샷 업로드: [`AppStore/screenshots-6.9/`](AppStore/screenshots-6.9/) (6.9" 이미지는 모든 iPhone에 공용 적용).
- 개인정보 처리방침 URL, 카테고리(교육), 연령 등급(4+), 가격(무료 등) 설정.

## 4. **서명 설정** (사용자, Xcode)
- Xcode에서 `PaperDaily.xcodeproj` 열기 → Target → **Signing & Capabilities**.
- **Automatically manage signing** 체크 → 본인 **Team** 선택 (2번의 개발자 계정).
- 이러면 배포 인증서/프로비저닝이 자동 생성됩니다. (현재 이 맥에는 서명 ID가 없어 제가 만들 수 없음.)

## 5. **아카이브 & 업로드** (사용자, Xcode)
- Xcode 상단 기기 선택을 **Any iOS Device (arm64)** 로.
- 메뉴 **Product → Archive**.
- Organizer 창이 뜨면 **Distribute App → App Store Connect → Upload**.
- (CLI 대안: 서명 설정 후 `xcodebuild -exportArchive`로 `.ipa` 생성 → Transporter 앱으로 업로드.)

## 6. **TestFlight로 먼저 검증** (권장)
- 업로드된 빌드는 App Store Connect → TestFlight에 나타남.
- 내부 테스터(본인 포함)에 배포해 실기기에서 확인. 심사 없이 즉시 가능.

## 7. **심사 제출** (사용자)
- App Store Connect → 앱 버전 → 빌드 선택 → **심사에 추가 → 제출**.
- 심사 소요 보통 1~3일. 승인 후 수동/자동 출시 선택.

---

## 참고 — 로컬 아카이브(서명 없음)
제가 만든 검증용 아카이브: `/tmp/PaperDaily.xcarchive` (서명 없음 → 업로드 불가, 빌드 확인용). 실제 배포는 4번 서명 설정 후 5번으로 새로 아카이브하세요.
