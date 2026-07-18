//  Localization.swift
//  App-wide UI language (ko/en). Strings transcribed 1:1 from the design handoff's
//  `L = { ko, en }` dictionary. Paper CONTENT (titles/abstracts/tags) stays in its
//  original language — only the UI chrome switches. Default follows the device locale.

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case ko, en
    var id: String { rawValue }
    var nativeName: String { self == .ko ? "한국어" : "English" }

    static var deviceDefault: AppLanguage {
        (Locale.preferredLanguages.first?.hasPrefix("ko") ?? false) ? .ko : .en
    }
}

/// A (ko, en) string pair resolved by the active language.
struct LocalizedString: Hashable {
    let ko: String
    let en: String
    init(_ ko: String, _ en: String) { self.ko = ko; self.en = en }
    func callAsFunction(_ lang: AppLanguage) -> String { lang == .ko ? ko : en }
}

/// All fixed UI-chrome strings for one language.
struct Strings {
    // Splash
    let loading: String
    // Onboarding
    let obTitle1, obTitle2, obSub: String
    let langLabel, freqLabel, interestsLabel: String
    let freqDaily, freqWeekly, freqMonthly: String
    let minSelect, next: String
    // Feed
    let filterAll, matchWord, save, saved, more: String
    let emptyFeed: String
    let offlineNote, loadFailNote: String
    // Tab bar
    let navHome, navLib, navStats, navSettings: String
    // Detail
    let detailBack, detailShare, detailSave, detailSaved, markRead, markedRead: String
    let reasonLabel, flagOriginal, flagTranslated: String
    let absLabel, absTranslated, showTranslation, showOriginal: String
    let citationsUnit, minReadUnit: String
    // Library
    let libTitle, libTab1, libTab2, libTab3, notStarted: String
    let remove, emptyToRead, emptySaved, emptyDone: String
    // Weekly summary
    let weekTitle, statRead, statSaved, statStreak, topicDist, highlightLabel: String
    // Settings
    let settingsTitle, setLanguage, setNotif, setTransLang, setSource, replayOnboarding: String
    let notifDaily, notifWeekly, notifMonthly: String
    // Review (에이전트 작성 리뷰)
    let readReview, reviewLoadFail, reviewRetry: String

    static func of(_ lang: AppLanguage) -> Strings { lang == .ko ? .ko : .en }

    static let ko = Strings(
        loading: "오늘의 논문을 고르는 중…",
        obTitle1: "어떤 분야를", obTitle2: "관심 있게 보시나요?",
        obSub: "관심 분야와 추천 주기를 고르면, 그에 맞춰 논문을 골라 드려요. 언제든 다시 바꿀 수 있어요.",
        langLabel: "언어", freqLabel: "추천 주기", interestsLabel: "관심 분야",
        freqDaily: "매일", freqWeekly: "매주", freqMonthly: "매달",
        minSelect: "최소 1개", next: "다음",
        filterAll: "전체", matchWord: "일치", save: "＋ 저장", saved: "✓ 저장됨", more: "자세히 →",
        emptyFeed: "해당 분야의 추천이 아직 없어요.",
        offlineNote: "오프라인 · 마지막으로 받은 추천",
        loadFailNote: "새 추천을 불러오지 못했어요 · 당겨서 새로고침",
        navHome: "홈", navLib: "라이브러리", navStats: "통계", navSettings: "설정",
        detailBack: "오늘의 추천", detailShare: "공유", detailSave: "저장하기", detailSaved: "저장됨",
        markRead: "읽음 표시", markedRead: "읽음 ✓",
        reasonLabel: "왜 추천했나요?", flagOriginal: "EN 원문", flagTranslated: "한국어 번역본",
        absLabel: "초록", absTranslated: "초록 · 번역본",
        showTranslation: "번역본 보기", showOriginal: "원문 보기",
        citationsUnit: "인용", minReadUnit: "분 읽기",
        libTitle: "라이브러리", libTab1: "읽을 목록", libTab2: "저장됨", libTab3: "완료", notStarted: "시작 전",
        remove: "삭제", emptyToRead: "읽을 논문이 없어요.", emptySaved: "저장한 논문이 없어요.", emptyDone: "완료한 논문이 없어요.",
        weekTitle: "이번 주 요약", statRead: "읽음", statSaved: "저장", statStreak: "연속",
        topicDist: "주제 분포", highlightLabel: "이번 주 하이라이트",
        settingsTitle: "설정", setLanguage: "언어", setNotif: "알림", setTransLang: "번역 언어",
        setSource: "논문 소스", replayOnboarding: "온보딩 다시 보기",
        notifDaily: "매일 아침", notifWeekly: "매주 월요일", notifMonthly: "매달 1일",
        readReview: "전체 리뷰 보기", reviewLoadFail: "리뷰를 불러오지 못했어요.", reviewRetry: "다시 시도"
    )

    static let en = Strings(
        loading: "Curating today’s papers…",
        obTitle1: "What fields", obTitle2: "are you interested in?",
        obSub: "Pick your fields and how often you’d like recommendations, and we’ll curate papers to match. You can change these anytime.",
        langLabel: "LANGUAGE", freqLabel: "FREQUENCY", interestsLabel: "FIELDS",
        freqDaily: "Daily", freqWeekly: "Weekly", freqMonthly: "Monthly",
        minSelect: "min 1", next: "Continue",
        filterAll: "All", matchWord: "match", save: "＋ Save", saved: "✓ Saved", more: "Read →",
        emptyFeed: "No recommendations in this field yet.",
        offlineNote: "Offline · last received picks",
        loadFailNote: "Couldn’t load new picks · pull to refresh",
        navHome: "Home", navLib: "Library", navStats: "Stats", navSettings: "Settings",
        detailBack: "Today", detailShare: "Share", detailSave: "Save", detailSaved: "Saved",
        markRead: "Mark read", markedRead: "Read ✓",
        reasonLabel: "Why this paper?", flagOriginal: "Original · EN", flagTranslated: "Korean · translated",
        absLabel: "ABSTRACT", absTranslated: "ABSTRACT · TRANSLATED",
        showTranslation: "View translation", showOriginal: "View original",
        citationsUnit: "citations", minReadUnit: "min read",
        libTitle: "Library", libTab1: "To read", libTab2: "Saved", libTab3: "Done", notStarted: "Not started",
        remove: "Remove", emptyToRead: "Nothing to read yet.", emptySaved: "No saved papers yet.", emptyDone: "No finished papers yet.",
        weekTitle: "This week", statRead: "Read", statSaved: "Saved", statStreak: "Streak",
        topicDist: "TOPIC MIX", highlightLabel: "HIGHLIGHT OF THE WEEK",
        settingsTitle: "Settings", setLanguage: "Language", setNotif: "Notifications", setTransLang: "Translation",
        setSource: "Paper source", replayOnboarding: "Replay onboarding",
        notifDaily: "Every morning", notifWeekly: "Every Monday", notifMonthly: "1st of each month",
        readReview: "Read Full Review", reviewLoadFail: "Couldn’t load the review.", reviewRetry: "Try again"
    )
}

/// Canonical topic/category value (Korean) → localized display label.
enum Topics {
    private static let map: [String: String] = [
        "머신러닝": "Machine Learning", "자연어처리": "NLP", "컴퓨터비전": "Computer Vision", "HCI": "HCI",
        "강화학습": "Reinforcement L.", "그래프 학습": "Graph Learning", "로보틱스": "Robotics", "생성모델": "Generative",
        "정보검색": "Info Retrieval", "음성·오디오": "Speech & Audio", "추천시스템": "Recommenders", "최적화": "Optimization",
        "기타": "Other", "전체": "All"
    ]
    /// Localized label for a canonical (Korean) topic/category/filter value.
    static func label(_ canonical: String, _ lang: AppLanguage) -> String {
        lang == .ko ? canonical : (map[canonical] ?? canonical)
    }
}

/// Known Korean hashtags → English. Unknown tags (e.g. from a remote feed) pass through.
enum Tags {
    private static let map: [String: String] = [
        "#검색증강": "#retrieval", "#LLM": "#LLM", "#인용신뢰도": "#faithfulness", "#디코딩": "#decoding",
        "#HCI": "#HCI", "#읽기경험": "#reading", "#요약": "#summarization", "#가독성": "#readability",
        "#생성모델": "#generative", "#효율화": "#efficiency", "#디퓨전": "#diffusion", "#미세조정": "#fine-tuning",
        "#사실성": "#factuality", "#지식그래프": "#knowledge-graph", "#평가": "#evaluation",
        "#대조학습": "#contrastive", "#표현학습": "#representation", "#정규화": "#regularization", "#저데이터": "#low-data",
        "#다국어": "#multilingual", "#임베딩": "#embeddings", "#정렬": "#alignment", "#저자원": "#low-resource",
        "#비디오": "#video", "#일관성": "#consistency", "#생성": "#generation",
        "#QA": "#QA", "#신뢰도": "#faithfulness", "#보정": "#calibration",
        "#어텐션": "#attention", "#장문맥": "#long-context", "#MoE": "#MoE"
    ]
    static func label(_ tag: String, _ lang: AppLanguage) -> String {
        lang == .ko ? tag : (map[tag] ?? tag)
    }
}

/// Localized feed header (date / title / subtitle / hint) by language × frequency.
struct FeedHeaderText {
    let date, title, subtitle, hint: String

    static func of(_ lang: AppLanguage, _ freq: Frequency) -> FeedHeaderText {
        switch (lang, freq) {
        case (.ko, .daily):   return .init(date: "2026. 7. 9  수요일", title: "오늘의 추천",  subtitle: "관심 분야에서 고른 5편 · 평균 정합성 92%",  hint: "매일 아침 새 논문 5편을 받아요.")
        case (.ko, .weekly):  return .init(date: "2026 · 28주차",       title: "이번 주 추천", subtitle: "관심 분야에서 고른 12편 · 평균 정합성 92%", hint: "매주 월요일 아침 12편을 받아요.")
        case (.ko, .monthly): return .init(date: "2026. 7월",           title: "이번 달 추천", subtitle: "관심 분야에서 고른 30편 · 평균 정합성 92%", hint: "매달 1일 30편을 받아요.")
        case (.en, .daily):   return .init(date: "Wed, Jul 9, 2026", title: "Today’s picks",       subtitle: "Curated 5 from your fields · avg. 92% match",  hint: "You’ll get 5 fresh papers every morning.")
        case (.en, .weekly):  return .init(date: "Week 28 · 2026",   title: "This week’s picks",   subtitle: "Curated 12 from your fields · avg. 92% match", hint: "You’ll get 12 papers every Monday morning.")
        case (.en, .monthly): return .init(date: "July 2026",        title: "This month’s picks",  subtitle: "Curated 30 from your fields · avg. 92% match", hint: "You’ll get 30 papers on the 1st of each month.")
        }
    }
}
