//  Models.swift
//  Domain types + the exact sample content from the handoff prototype.

import Foundation

// MARK: - Recommendation frequency (온보딩 세그먼트 → 피드 헤더 연동)

enum Frequency: String, CaseIterable, Identifiable {
    case daily, weekly, monthly
    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily:   "매일"
        case .weekly:  "매주"
        case .monthly: "매달"
        }
    }

    /// 온보딩 안내문.
    var hint: String {
        switch self {
        case .daily:   "매일 아침 새 논문 5편을 받아요."
        case .weekly:  "매주 월요일 아침 12편을 받아요."
        case .monthly: "매달 1일 30편을 받아요."
        }
    }

    /// 피드 헤더 — 날짜.
    var feedDate: String {
        switch self {
        case .daily:   "2026. 7. 9  수요일"
        case .weekly:  "2026 · 28주차"
        case .monthly: "2026. 7월"
        }
    }

    /// 피드 헤더 — 타이틀.
    var feedTitle: String {
        switch self {
        case .daily:   "오늘의 추천"
        case .weekly:  "이번 주 추천"
        case .monthly: "이번 달 추천"
        }
    }

    /// 피드 헤더 — 부제.
    var feedSub: String {
        switch self {
        case .daily:   "관심 분야에서 고른 5편 · 평균 정합성 92%"
        case .weekly:  "관심 분야에서 고른 12편 · 평균 정합성 92%"
        case .monthly: "관심 분야에서 고른 30편 · 평균 정합성 92%"
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

    /// "왜 추천했나요?" 본문. `**...**` 는 볼드(마크다운).
    let reason: String

    func title(translated: Bool) -> String { translated ? detailTitleKO : detailTitleEN }
    func authors(translated: Bool) -> String { translated ? authorsKO : authorsEN }
    func abstract(translated: Bool) -> String { translated ? abstractKO : abstractEN }
}

// MARK: - Library row

struct LibraryItem: Identifiable, Hashable {
    let paper: Paper           // full record → row taps open the detail screen
    let relativeDate: String
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
