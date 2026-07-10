# Handoff: 논문 데일리 (Daily Papers) — 논문 추천 리더 앱

## Overview
대학원생·연구자를 위한 **매일 논문 추천 모바일 앱**의 디자인입니다. 관심 분야를 온보딩에서 고르면, 매일 아침 정합성(매칭) 높은 논문을 추천 피드로 제공하고, 상세 화면에서 원문(영어)을 읽으며 한국어 번역본을 토글로 볼 수 있습니다. 저장/읽을 목록(라이브러리)과 주간 요약(통계)까지 5개 화면으로 구성됩니다.

대상 플랫폼: **모바일(iOS/Android)**. 기준 캔버스: **390 × 844 pt (iPhone 논리 해상도)**.

## About the Design Files
이 번들의 HTML 파일은 **디자인 레퍼런스(프로토타입)** 입니다 — 의도한 룩앤필과 동작을 보여주는 시안이며, 그대로 복붙해 배포할 프로덕션 코드가 아닙니다. 목표는 이 디자인을 **대상 코드베이스의 기존 환경(React Native, Flutter, SwiftUI, 네이티브 등)과 그 패턴·라이브러리로 재구현**하는 것입니다. 아직 코드베이스가 없다면, 이 앱에 가장 적합한 프레임워크(모바일이므로 React Native 또는 Flutter 권장)를 선택해 구현하세요.

`design-prototype.html` 을 브라우저로 열면 실제 인터랙션(번역 토글)을 확인할 수 있습니다. `design-source.html` 은 마크업/구조 참고용 소스입니다.

## Fidelity
**High-fidelity (hifi).** 최종 색상·타이포그래피·간격·인터랙션이 확정된 픽셀 단위 시안입니다. 아래 명세의 정확한 값(hex, px, weight)을 대상 코드베이스의 컴포넌트/토큰으로 그대로 재현하세요.

---

## Design Tokens

### Colors
| 역할 | Hex |
|---|---|
| 데스크(캔버스) 배경 | `#DAD4C7` |
| 앱 배경 | `#F4F0E8` |
| 카드/표면 | `#FFFFFF` |
| 텍스트 기본 (ink) | `#201C16` |
| 텍스트 본문(초록) | `#3F3A31` |
| 텍스트 보조(저자/부제) | `#5F5849` |
| 텍스트 뮤트 | `#6E675B` |
| 텍스트 페인트(라벨) | `#8A8375` / `#948D7C` |
| 섹션 라벨(mono) | `#A39A88` |
| 날짜/약한 mono | `#B0A997` |
| 태그 텍스트(mono) | `#8A8073` |
| 경계선(기본) | `#E7E0D2` |
| 카드 경계선 | `#EDE6D8` |
| 구분선 | `#EFE8DB` |
| 트랙/태그 배경 | `#EDE7DB` |
| **액센트(테라코타)** | `#C0603A` |
| 액센트 딥(텍스트/링크) | `#A34E2E` |
| 액센트 소프트 배경 | `#F4E4D7` |
| 액센트 소프트 경계선 | `#DDA684` / `#E4CBB9` |
| 아웃라인 버튼 경계선 | `#DBD3C3` |
| 하단 탭바 배경 | `rgba(244,240,232,0.94)` |

액센트는 단일 색(`#C0603A`) + 투명도 변주로 사용(예: 주제 분포 막대 opacity 1 / 0.82 / 0.64 / 0.46).

### Typography
- **Serif — `Newsreader`** (weights 400·500·600): 논문 제목, 대형 헤딩, 통계 숫자. 대부분 weight 500.
- **Sans — `Public Sans`** (400·500·600·700): UI·버튼·본문.
- **Mono — `JetBrains Mono`** (400·500): 메타데이터, 섹션 라벨, 학회명, 날짜, 퍼센트, 매칭 배지.

| 용도 | Font / Weight | Size | 기타 |
|---|---|---|---|
| 화면 타이틀(오늘의 추천/라이브러리/이번 주 요약) | Newsreader 500 | 30 | ls −0.02em |
| 온보딩 헤딩 | Newsreader 500 | 30 | lh 1.22 |
| 논문 상세 H1 | Newsreader 500 | 26 | lh 1.28, ls −0.02em |
| 피드 카드 제목 | Newsreader 500 | 19 | lh 1.3, ls −0.01em |
| 하이라이트 카드 제목 | Newsreader 500 | 18 | lh 1.3 |
| 라이브러리 행 제목 | Newsreader 500 | 16 | lh 1.3 |
| 통계 숫자 | Newsreader 500 | 30 | lh 1 |
| 초록 본문(상세) | Public Sans 400 | 14.5 | lh 1.68 |
| 피드 초록(2줄 클램프) | Public Sans 400 | 13 | lh 1.55, `-webkit-line-clamp:2` |
| 저자 | Public Sans 400 | 13–14 | `#6E675B` |
| 섹션 라벨(mono) | JetBrains Mono 400 | 11 | ls 0.08em, UPPERCASE, `#A39A88` |
| 학회·메타(mono) | JetBrains Mono 400/500 | 11–13 | |
| 탭바 라벨 | Public Sans 500/600 | 11 | |

### Spacing / Radius / Shadow
- 폰 프레임: **390×844**, radius **46**, bg `#F4F0E8`, shadow `0 0 0 1px rgba(30,22,14,.05), 0 34px 60px -22px rgba(45,32,20,.34)`.
- 콘텐츠 패딩: 좌우 **26**(피드 22), 상단 8. 하단 여백: 탭바 화면 **104**, 온보딩 CTA **130**.
- 카드: radius **22**, padding **19**, border 1px `#EDE6D8`, shadow `0 1px 2px rgba(40,30,20,.03), 0 14px 26px -20px rgba(40,30,20,.28)`. 카드 간 gap **15**.
- 라이브러리 행: radius **16**, padding 15×16. 통계 카드: radius **18**, padding 16×14. 리즌/소프트 카드: radius **18**, bg `#F4E4D7`.
- 프로그레스 트랙: height 4(온보딩)/8(라이브러리)/10(주제분포), radius 999, bg `#EDE7DB`, fill `#C0603A`.
- 칩/배지: pill(radius 999) 또는 radius 7(태그). 
- 하단 탭바: height **84**, border-top 1px `#E7E0D2`, 4개 항목 `space-around`, 활성 항목 위 5px 액센트 점.
- 주 버튼(CTA): height **54**, radius **16**, bg `#C0603A`, 텍스트 Public Sans 600 16 white. 보조/아웃라인: height 50, radius 14, border 1px `#DBD3C3`, bg white.

### Links
기본 링크 `#A34E2E`, hover `#8f4023`.

---

## Screens / Views

### 0. 실행화면 — 스플래시 / 런치 스크린
- **Purpose**: 앱 콜드 스타트 시 브랜드 노출 + 초기 데이터(추천) 로딩 커버.
- **Layout**: 전체 배경 액센트 `#C0603A`. 상태바(밝은색 `#F7E9E1`) → 중앙 로고 블록 → 하단 로딩 인디케이터.
- **Components**:
  - 워드마크: "Daily Papers"(필기체 **Dancing Script**, OFL 오픈 라이선스, weight 600 / 80 / `#F7ECE5`). 한자·별도 아이콘 없음.
  - 아래 짧은 구분선(54×1.5px, `rgba(247,236,229,.5)`) + 태그라인 "EXPAND YOUR INSIGHT"(mono 13, ls 0.16em, uppercase, `#EBBFA9`).
  - 하단: 인디터미네이트 로딩 바(104×3, 트랙 `rgba(247,236,229,.24)`, fill `#F7ECE5`가 좌→우로 흐르는 `splashBar` 애니메이션 1.15s 무한) + "오늘의 논문을 고르는 중…"(mono 11 `#EBBFA9`).
  - 진입 애니메이션: 로고/타이틀 블록 `splashIn` 0.7s(fade + 상승 + scale 0.96→1).
- **Behavior**: 초기 로딩(추천 프리페치/세션 복원) 완료 시 자동 전환 — 신규 사용자 → 온보딩, 기존 사용자 → 추천 피드. 네이티브에서는 OS 런치 스크린(정적 로고)과 이 인앱 스플래시(로딩 인디케이터)를 함께 사용 권장.

### 1. 온보딩 — 관심 분야 설정
- **Purpose**: 추천 개인화를 위한 관심 연구 분야 선택.
- **Layout**: 상단 진행 표시(`02 / 03` mono + 66% 진행 바) → 헤딩 → 부제 → 칩 그리드(flex-wrap, gap 10) → 하단 고정 CTA 바(그라데이션 페이드).
- **Components**:
  - 헤딩: "어떤 분야를 / 관심 있게 보시나요?" (Newsreader 500 / 30).
  - 부제: "관심 분야와 추천 주기를 고르면, 그에 맞춰 논문을 골라 드려요. 언제든 다시 바꿀 수 있어요." (`#6E675B` 14.5).
  - **추천 주기 세그먼트 컨트롤**: 라벨 "추천 주기"(mono) + 3분할 세그먼트(**매일 / 매주 / 매달**). 트랙 bg `#EDE7DB`, radius 14, padding 4. 활성 세그먼트 = white pill(radius 11, shadow `0 1px 2px rgba(40,30,20,.10)`, text `#201C16` 600), 비활성 text `#8A8073`. **기본값 매일**. 아래 안내문(13, `#948D7C`)이 선택에 따라 변경: 매일 "매일 아침 새 논문 5편을 받아요." / 매주 "매주 월요일 아침 12편을 받아요." / 매달 "매달 1일 30편을 받아요.". 이어서 라벨 "관심 분야"(mono) 아래 분야 칩.
  - 분야 칩 12개: 머신러닝, 자연어처리✓, 컴퓨터비전, HCI✓, 강화학습, 그래프 학습, 로보틱스, 생성모델✓, 정보검색, 음성·오디오, 추천시스템, 최적화. **선택됨**(자연어처리·HCI·생성모델): text `#A34E2E` 600, bg `#F4E4D7`, border 1px `#DDA684`, 끝에 `✓`. **미선택**: text `#5F5849`, bg white, border 1px `#E7E0D2`. 칩 padding 11×16, pill.
  - 하단 바: "3개 선택됨 · 최소 1개"(mono 12 `#948D7C`, center) + CTA "다음".

### 2. 추천 피드 — 오늘의 추천 (메인)
- **Purpose**: 오늘 추천 논문 열람 및 저장/상세 진입.
- **Layout**: 헤더(날짜/타이틀/부제) → 가로 스크롤 필터 칩 → 세로 카드 리스트 → 하단 탭바(홈 활성).
- **Components**:
  - 날짜·타이틀·부제는 **온보딩의 추천 주기에 연동**됨 — 매일: "2026. 7. 9  수요일" / "오늘의 추천" / "관심 분야에서 고른 5편 · 평균 정합성 92%". 매주: "2026 · 28주차" / "이번 주 추천" / "…고른 12편…". 매달: "2026. 7월" / "이번 달 추천" / "…고른 30편…". (날짜 mono 12 `#A34E2E`, 타이틀 Newsreader 30.)
  - 필터 칩(가로 스크롤): **전체**(활성: white/`#201C16` pill), 자연어처리, 생성모델, HCI(비활성: `#6E675B`/white/border).
  - **논문 카드**(3개 표시) 구조: 상단 행 = 학회·언어표식(mono, 예 `ACL 2026 · EN`) + 매칭 배지(mono 11, `#A34E2E` on `#F4E4D7` pill, 예 "96% 일치") → 제목(영문 원문, Newsreader 19) → 저자(`J. Kim, R. Alvarez +3`) → 초록 2줄(영문, clamp) → 태그 칩(`#검색증강` `#LLM` 등, mono on `#EDE7DB`) → 구분선 → 액션 행(`＋ 저장` 좌 / `자세히 →` 우, `#A34E2E`).
  - 카드 데이터:
    1. ACL 2026 · 96% — "Grounded Consistency in RAG: Decoding for Citation Faithfulness" / J. Kim, R. Alvarez +3 / #검색증강 #LLM
    2. CHI 2026 · 92% — "Reading Flows for Researchers: How Peripheral Summaries Shape Comprehension" / S. Lee, M. Chen +2 / #HCI #읽기경험
    3. NeurIPS 2025 · 89% — "Low-Cost Fine-Tuning by Reusing Diffusion Sampling Trajectories" / H. Park +4 / #생성모델 #효율화

### 3. 논문 상세 (원문 + 번역 토글)
- **Purpose**: 논문 원문(영어) 정독, 한국어 번역본 확인, 저장/읽음 처리.
- **Layout**: 뒤로가기 바 → 학회 라벨 + 언어 플래그 → 제목 → 저자 → 메타 행(구분선) → 액션 버튼 2개 → 초록 섹션(헤더 + 토글 버튼) → 초록 본문 → 태그 → "왜 추천했나요?" 리즌 카드. **이 화면은 세로 스크롤(하단 탭바 없음, 푸시 뷰).**
- **Components**:
  - 뒤로가기 행: "← 오늘의 추천"(`#6E675B` 600) / "공유"(`#948D7C`).
  - 학회 라벨 "ACL 2026 · LONG PAPER"(mono 11, `#A34E2E`) + **언어 플래그 칩**(mono 10, `#8A8073` on `#EDE7DB`): 기본 `EN 원문`, 번역 시 `한국어 번역본`.
  - H1 제목(원문/번역 토글). 저자(원문 "Jiwon Kim, Rafael Alvarez, Mei Chen, +2 others" / 번역 "김지원, 라파엘 알바레즈, 메이 첸 외 2명").
  - 메타 행(mono 12 `#8A8073`, 하단 border): `2026` · `인용 14` · `12분 읽기`.
  - 액션 버튼: **저장하기**(filled `#C0603A`, height 50) + **읽음 표시**(outline, border `#DBD3C3`), flex 1:1 gap 10.
  - 초록 섹션 헤더: 라벨(`ABSTRACT` / 번역 시 `초록 · 번역본`) 좌, **토글 버튼** 우 — pill, bg `#F4E4D7`, border `#E4CBB9`, text `#A34E2E` 600 12.5, 라벨 "번역본 보기" ↔ "원문 보기".
  - 초록 본문(14.5 / lh 1.68 / `#3F3A31`) — 원문(영문 3문장) / 번역(국문 3문장) 스왑.
  - 태그 4개: #검색증강 #LLM #인용신뢰도 #디코딩.
  - 리즌 카드(bg `#F4E4D7`, radius 18): 라벨 "왜 추천했나요?"(mono `#A34E2E`) + "회원님이 저장한 'RAG 인용 신뢰도' 논문과 방법론이 유사하고, 자주 읽는 ACL 계열이에요."(`#6B4A38`).

### 4. 라이브러리 — 저장/읽을 목록
- **Purpose**: 저장한 논문의 읽기 진행 관리.
- **Layout**: 타이틀 → 탭 3개 → 행 리스트 → 하단 탭바(라이브러리 활성).
- **Components**:
  - 타이틀 "라이브러리"(Newsreader 30).
  - 탭: **읽을 목록**(활성: 하단 2px `#C0603A` 언더라인, `#201C16` 600) / 저장됨 / 완료(비활성 `#948D7C`).
  - 행(4개): 상단 = 학회(mono) + 상대 날짜(mono `#B0A997`, 예 "2일 전"); 제목(영문 Newsreader 16); 하단 = 진행 바 + `%`(mono). 데이터: EMNLP 2025 / "Evaluating the Factuality of Long-Form Summaries with Knowledge Graphs" / 62% · ICLR 2026 / "Mitigating Representation Collapse in Contrastive Learning on Small Data" / 28% · TACL 2025 / "Anchor Selection for Cross-Lingual Alignment of Multilingual Embeddings" / 시작 전 · CVPR 2025 / "Temporal Consistency Regularization for Video Diffusion Models" / 시작 전.

### 5. 주간 요약 — 이번 주 요약 (통계)
- **Purpose**: 한 주 읽기 활동 회고.
- **Layout**: 날짜 범위 → 타이틀 → 통계 카드 3개(가로) → 주제 분포 막대 → 하이라이트 카드 → 하단 탭바(통계 활성).
- **Components**:
  - 날짜 "7월 3일 – 7월 9일"(mono `#A34E2E`); 타이틀 "이번 주 요약".
  - 통계 카드 3개(flex, gap 11): **읽음 12**, **저장 8**(white 카드), **연속 5일**(액센트 카드 bg `#C0603A`, 숫자 white / 라벨 `#F4E0D4`). 숫자 Newsreader 30, 라벨 mono 11.
  - "주제 분포"(섹션 라벨) — 막대 4개: 자연어처리 42%, 생성모델 26%, HCI 20%, 기타 12%. 각 행 = 라벨(72px) + 트랙(fill `#C0603A`, opacity 1/0.82/0.64/0.46) + `%`(mono, 우측 정렬).
  - "이번 주 하이라이트" 카드: "가장 오래 읽은 논문 · 27분"(mono) + 제목(영문 Newsreader 18) + "J. Kim +4 · ACL 2026".

---

## Interactions & Behavior
- **언어 전환(앱 전역, 신규)**: 단일 상태 `lang`('ko'|'en', 기본 'ko'). 온보딩 최상단 "언어 / LANGUAGE" 세그먼트(한국어 | English)에서 선택. 전환 시 **모든 화면의 UI 크롬**(제목·라벨·버튼·탭·네비게이션·필터·통계 라벨·상대 날짜·추천 주기 문구·매칭 배지의 "일치/match" 등)이 즉시 한/영으로 스왑됨. 구현: 문자열 사전 `L = { ko:{…}, en:{…} }`에서 `S = L[lang]`을 골라 렌더. 실제 앱에서는 표준 i18n(예: i18next / Flutter intl) 리소스로 대체하고, OS 로케일 기본값 + 설정에서 변경 가능하게 할 것. **논문 본문(제목/초록)은 원문(영어) 고정**이며 언어 설정과 무관 — 한국어 본문은 아래 번역 토글로만 노출.
- **번역 토글(상세 화면)**: `translated` boolean(기본 false). 논문 원문(영어) ↔ 한국어 번역본을 스왑 — 제목·저자·초록 본문·언어 플래그·초록 라벨·버튼 라벨이 함께 전환. `lang`과 독립적(영어 UI에서도 한국어 번역 제공). 실제 앱에서는 번역 API 온디맨드 호출 + 로딩/실패 처리.
- **추천 주기 선택(온보딩)**: `frequency` 상태(daily/weekly/monthly, 기본 daily). 세그먼트 선택 시 온보딩 안내문과 **피드 화면의 날짜·타이틀·부제**가 즉시 연동 전환됨. 실제 앱에서는 이 값이 추천 배치 스케줄(매일/매주/매달 알림·페칭 주기)을 결정.
- **필터 칩(피드)**: 선택 시 활성 스타일 전환 + 리스트 필터링.
- **탭 전환(라이브러리)**: 읽을 목록/저장됨/완료 데이터셋 스위칭.
- **하단 탭바**: 홈 / 라이브러리 / 통계 / 설정 네비게이션. 활성 항목 = 라벨 600 `#201C16` + 상단 5px 액센트 점.
- **카드/행 탭** → 논문 상세로 이동. `저장`/`읽음 표시`는 라이브러리·통계 상태에 반영.
- 애니메이션: 시안에는 전환 애니메이션이 없음(즉시 전환). 필요 시 표준 네이티브 push/모달 전환 사용.

## State Management
- `lang: 'ko' | 'en'` — 앱 UI 언어(기본 ko). 온보딩에서 선택, 모든 화면 크롬에 반영. (논문 본문 언어와는 별개.)
- `interests: string[]` — 온보딩 선택 분야(추천 쿼리에 사용).
- `frequency: 'daily' | 'weekly' | 'monthly'` — 추천 주기(기본 daily). 피드 헤더 문구와 알림·페칭 스케줄에 반영.
- `feed: Paper[]` — 오늘의 추천(각 항목에 `matchScore`).
- `activeFilter: string` — 피드 필터.
- `paper.translated: boolean` (또는 상세 화면 로컬 상태) — 번역 토글.
- `library`: `{ toRead, saved, done }` 각 항목 `progress: number(0–100)`.
- `weeklyStats`: `{ read, saved, streak, topicDistribution[], highlight }`.
- 데이터 페칭: 논문 소스 API(예: arXiv, Semantic Scholar), 번역 API, (개인화 추천을 위한) 매칭/스코어링 로직, 사용자 계정·동기화.

## Assets
- 외부 이미지 없음. 아이콘/일러스트 미사용(텍스트·기하 도형만). 상태바 배터리는 사각형 도형으로 표현 — 실제 앱에선 OS 상태바 사용.
- 폰트: Google Fonts — **Newsreader**, **Public Sans**, **JetBrains Mono**. (네이티브에서는 번들 폰트로 포함하거나 유사 시스템 폰트로 대체.)

## Files
- `design-prototype.html` — 자체 완결 프로토타입(브라우저에서 열어 번역 토글 등 실제 동작 확인).
- `design-source.html` — 구조 참고용 소스 마크업.
