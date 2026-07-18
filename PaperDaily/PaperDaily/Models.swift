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

    /// 번역본이 실제로 존재하는가. 생성기는 번역이 없으면 KO 필드에 원문을 그대로 넣으므로
    /// (titleKO == titleEN), 이를 확인하지 않으면 "번역본 보기"가 같은 영문을 다시 보여준다.
    var hasTranslation: Bool {
        detailTitleKO != detailTitleEN || authorsKO != authorsEN || abstractKO != abstractEN
    }

    /// 카드에 실제로 렌더되는 초록의 언어 표기. 실피드는 한국어 요약, 샘플은 영문이라
    /// "EN"을 고정으로 쓰면 한국어 본문 위에 EN이 붙는다.
    var feedAbstractLanguage: String {
        let hasHangul = feedAbstract.unicodeScalars.contains { scalar in
            (0xAC00...0xD7A3).contains(scalar.value)   // 음절
                || (0x1100...0x11FF).contains(scalar.value)   // 자모
                || (0x3130...0x318F).contains(scalar.value)   // 호환 자모
        }
        return hasHangul ? "KO" : "EN"
    }

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
    /// 카테고리명이 곧 식별자 — 매 렌더마다 새 UUID가 생기면 ForEach 애니메이션이 튄다.
    var id: String { label }
    let label: String
    let percent: Int
    let opacity: Double
}
