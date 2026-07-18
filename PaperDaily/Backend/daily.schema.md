# `daily.json` — Mac Mini → 앱 피드 계약

맥미니의 매일 논문 찾기 파이프라인은 결과를 아래 스키마의 **`daily.json`** 하나로 출력해서, 앱이 읽을 수 있는 URL(HTTPS 권장)에 게시하면 됩니다. 앱은 이 URL에서 fetch → 실패 시 캐시 → 그래도 없으면 번들 샘플로 폴백합니다.

- 앱 설정: `PaperDaily/Config.swift`의 `defaultFeedURLString`에 이 파일의 URL을 넣으세요.
- 예시 파일: [`daily.example.json`](daily.example.json) (그대로 복제해 값만 바꾸면 됨).

## 최상위 객체
| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `version` | int | 선택 | 스키마 버전. 현재 `1`. |
| `generatedAt` | string(ISO8601) | 선택 | 생성 시각. |
| `frequency` | string | 선택 | `daily`\|`weekly`\|`monthly` (참고용). |
| `header` | object | 선택 | 피드 상단 문구 오버라이드. 없으면 앱이 추천 주기로 자동 생성. |
| `papers` | array | **필수** | **오늘 공개된 배치**의 논문 목록. 비어 있으면 앱은 샘플로 폴백. |
| `archive` | array | 선택 | 과거 배치의 논문 목록(원소 스키마는 `papers`와 동일). 피드 화면에는 표시되지 않고, 라이브러리의 저장/읽음 항목을 해석할 때만 사용됩니다. 없으면 `[]`로 처리. |

### 공개 페이싱 계약 (`papers` vs `archive`)
`papers`는 **오늘 공개된 배치**만 담습니다(기본 5편/일). 나머지 코퍼스는 `archive`에 담아, 이전에 저장/읽음 처리한 논문이 피드에서 빠져도 라이브러리에서 계속 해석되게 합니다. 공개 이력은 생성기가 `release-schedule.json`으로 관리하며, 새 리뷰가 없는 날은 최근 배치를 그대로 유지합니다. `archive`가 없는 구버전 피드도 그대로 동작합니다(빈 배열로 처리).

### `header`
| 필드 | 타입 | 설명 |
|---|---|---|
| `date` | string | 예 `"2026. 7. 10  목요일"` |
| `title` | string | 예 `"오늘의 추천"` |
| `subtitle` | string | 예 `"관심 분야에서 고른 5편 · 평균 정합성 92%"` |
> 세 필드가 모두 있어야 오버라이드가 적용됩니다.

### `papers[]`
| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `id` | string | **필수** | 고유 ID (arXiv id 등). |
| `venue` | string | **필수** | 학회 짧은 이름. 예 `"ACL 2026"`. |
| `venueDetail` | string | 선택 | 상세용. 예 `"ACL 2026 · LONG PAPER"`. 없으면 `venue`. |
| `matchScore` | int | **필수** | 정합성 % (0–100). |
| `category` | string | **필수** | 피드 필터 카테고리. 예 `"자연어처리"`. 필터 칩은 이 값들로 자동 구성. |
| `feedTitle` | string | **필수** | 카드 제목(영문 원문 축약). |
| `authorsShort` | string | **필수** | 카드 저자. 예 `"J. Kim, R. Alvarez +3"`. |
| `feedAbstract` | string | **필수** | 카드 초록(2줄 클램프). |
| `tags` | string[] | **필수** | 카드 태그. 예 `["#검색증강","#LLM"]`. |
| `titleEN` / `titleKO` | string | **필수** | 상세 제목 (원문/번역). |
| `authorsEN` / `authorsKO` | string | **필수** | 상세 저자 (원문/번역). |
| `abstractEN` / `abstractKO` | string | **필수** | 상세 초록 (원문/번역). |
| `detailTags` | string[] | 선택 | 상세 태그. 없으면 `tags`. |
| `year` | string | **필수** | 예 `"2026"`. |
| `citations` | int | **필수** | 인용 수. |
| `readMinutes` | int | **필수** | 예상 읽기 분. |
| `reason` | string | **필수** | "왜 추천했나요?" 본문(한국어). `**...**`로 볼드 지정 가능(마크다운). |
| `reasonEn` | string | 선택 | 영어 UI일 때 표시할 추천 이유. 없으면 `reason`을 그대로 사용. |
| `reviewURL` | string | 선택 | 에이전트가 작성한 리뷰 페이지 URL(HTTPS). 있으면 상세 화면에 "전체 리뷰 보기" 버튼이 나타나고, 인앱 웹뷰로 열립니다. 없으면 버튼 미표시. |

## 번역 필드에 대해
현재 계약은 `*KO` 번역을 **맥미니에서 미리 채워** 보내는 구조입니다(가장 단순·확실). 원한다면 이후 앱에서 온디맨드 번역 API로 대체할 수 있으나, 우선은 맥미니 쪽에서 번역까지 붙여 JSON에 담는 것을 권장합니다.

## 운영 주의
- **HTTPS 필수** (iOS ATS). 집 IP 직접 노출 대신 정적 호스팅/터널(GitHub Pages·S3·Cloudflare Tunnel 등) 권장.
- 매일 파이프라인이 이 파일을 덮어쓰면 앱은 당겨서 새로고침 시 최신본을 받습니다.
- 스키마가 안 맞거나 서버가 죽어도 앱은 **마지막 캐시 → 샘플** 순으로 폴백하므로 빈 화면이 되지 않습니다.

## 로컬 테스트
```bash
# 예시 JSON을 로컬 HTTP로 서빙
cd PaperDaily/Backend && python3 -m http.server 8787
# 앱을 그 URL로 실행 (시뮬레이터, ATS 예외 필요 — 아래 참고)
env SIMCTL_CHILD_PD_FEED_URL="http://localhost:8787/daily.example.json" \
  xcrun simctl launch booted com.paperdaily.app
```
> `http://localhost` 테스트는 ATS 때문에 디버그 빌드에 로컬 예외가 필요할 수 있습니다. 프로덕션은 HTTPS URL을 쓰면 예외 없이 동작합니다. `file://` 경로도 지원합니다(`PD_FEED_URL=file:///path/daily.json`).
