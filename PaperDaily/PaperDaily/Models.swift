//  Models.swift
//  Domain types + the exact sample content from the handoff prototype.

import Foundation

// MARK: - Recommendation frequency (온보딩 세그먼트 → 피드 헤더 연동)

enum Frequency: String, CaseIterable, Identifiable {
    case daily, weekly, monthly
    var id: String { rawValue }

    /// Localized segment label. (Header date/title/subtitle/hint → FeedHeaderText.)
    func label(_ s: Strings) -> String {
        switch self {
        case .daily:   s.freqDaily
        case .weekly:  s.freqWeekly
        case .monthly: s.freqMonthly
        }
    }
}

// MARK: - Paper

struct Paper: Identifiable, Hashable {
    let id: String
    let venue: String           // 카드/행 학회 라벨 (예: "ACL 2026")
    let venueDetail: String     // 상세 학회 라벨 (예: "ACL 2026 · LONG PAPER")
    let matchScore: Int         // 정합성 %
    let filterCategory: String  // 피드 필터용 (자연어처리 / 생성모델 / HCI)

    // 피드 카드
    let feedTitle: String       // 카드 제목(영문)
    let authorsShort: String    // "J. Kim, R. Alvarez +3"
    let feedAbstract: String    // 2줄 클램프 초록(영문)
    let tags: [String]          // #검색증강, #LLM ...

    // 상세 (원문/번역 스왑)
    let detailTitleEN: String
    let detailTitleKO: String
    let authorsEN: String
    let authorsKO: String
    let abstractEN: String
    let abstractKO: String
    let detailTags: [String]

    // 메타
    let year: String
    let citations: Int
    let readMinutes: Int

    /// "왜 추천했나요?" 본문(UI 언어 따름). `**...**` 는 볼드(마크다운).
    let reason: LocalizedString

    /// 에이전트 작성 리뷰 페이지 URL. nil이면 상세 화면에 리뷰 버튼이 숨겨진다.
    /// (`var` + 기본값 → memberwise init에서 생략 가능, 기존 SampleData 호출부 유지.)
    var reviewURL: String? = nil

    /// 전처리된 리뷰 마크다운 URL (file:// 포함). 있으면 네이티브 리더(ReviewReaderView)가
    /// WKWebView(reviewURL) 대신 사용된다. 피드가 필드를 아직 안 주는 동안은 nil.
    var reviewMarkdownURL: String? = nil

    func title(translated: Bool) -> String { translated ? detailTitleKO : detailTitleEN }
    func authors(translated: Bool) -> String { translated ? authorsKO : authorsEN }
    func abstract(translated: Bool) -> String { translated ? abstractKO : abstractEN }
}

// MARK: - Library row

struct LibraryItem: Identifiable, Hashable {
    let paper: Paper           // full record → row taps open the detail screen
    let relativeDate: LocalizedString
    /// nil == 시작 전.
    let progress: Int?
    var id: String { paper.id }
}

// MARK: - Weekly summary

struct TopicShare: Identifiable, Hashable {
    let id = UUID().uuidString
    let label: String
    let percent: Int
    let opacity: Double
}

struct Highlight: Hashable {
    let subtitle: String    // "가장 오래 읽은 논문 · 27분"
    let title: String
    let meta: String        // "J. Kim +4 · ACL 2026"
}

struct WeeklyStats {
    let dateRange: String
    let read: Int
    let saved: Int
    let streak: String      // "5일"
    let topics: [TopicShare]
    let highlight: Highlight
}
