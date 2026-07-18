//  AppState.swift
//  Single observable store for cross-screen state (per handoff › State Management).

import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case home, library, stats, settings
    var id: String { rawValue }

    func label(_ s: Strings) -> String {
        switch self {
        case .home:     s.navHome
        case .library:  s.navLib
        case .stats:    s.navStats
        case .settings: s.navSettings
        }
    }
}

enum LibraryTab: String, CaseIterable, Identifiable {
    case toRead, saved, done
    var id: String { rawValue }

    func label(_ s: Strings) -> String {
        switch self {
        case .toRead: s.libTab1
        case .saved:  s.libTab2
        case .done:   s.libTab3
        }
    }

    var items: [LibraryItem] {
        switch self {
        case .toRead: SampleData.toRead
        case .saved:  SampleData.saved
        case .done:   SampleData.done
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    // 앱 UI 언어 (기본: 기기 언어) — 변경 시 영속
    @Published var lang: AppLanguage = .ko {
        didSet { UserDefaults.standard.set(lang.rawValue, forKey: "PD_LANG") }
    }
    var strings: Strings { Strings.of(lang) }

    // 실행화면(스플래시)
    @Published var isLaunching = true

    // 온보딩 — 완료 여부·관심 분야·추천 주기 모두 영속 (4-4)
    @Published var onboarded = false {
        didSet { UserDefaults.standard.set(onboarded, forKey: "PD_ONBOARDED_DONE") }
    }
    @Published var interests: Set<String> = SampleData.defaultInterests {
        didSet { UserDefaults.standard.set(Array(interests).sorted(), forKey: "PD_INTERESTS") }
    }
    @Published var frequency: Frequency = .daily {
        didSet { UserDefaults.standard.set(frequency.rawValue, forKey: "PD_FREQUENCY") }
    }

    // 네비게이션
    @Published var selectedTab: Tab = .home

    // 피드 (원격 daily.json 로드 → 없으면 샘플)
    @Published var activeFilter: String = "전체"
    @Published var feed: [Paper] = SampleData.feed
    @Published var feedArchive: [Paper] = []   // 과거 배치 — 피드에는 안 보이고 라이브러리 해석용
    @Published var feedHeader: FeedHeader? = nil
    @Published var feedSource: FeedSource = .sample
    @Published var isLoadingFeed = false
    private var didInitialLoad = false

    // 저장/읽음 상태 (카드·상세 액션 → 라이브러리 탭에 반영) — 변경 시 영속 (PD_LANG과 동일 패턴)
    @Published var savedIDs: Set<String> = [] {
        didSet { UserDefaults.standard.set(Array(savedIDs), forKey: "PD_SAVED_IDS") }
    }
    @Published var readIDs: Set<String> = [] {
        didSet { UserDefaults.standard.set(Array(readIDs), forKey: "PD_READ_IDS") }
    }
    // 읽을 목록(진행 중) — 시드된 목록, 스와이프/롱프레스로 삭제 가능
    @Published var toReadItems: [LibraryItem] = SampleData.toRead

    // UI 테스트/미리보기 진입용 (프로덕션 무동작: env 미설정 시 nil/false).
    // 예: SIMCTL_CHILD_PD_ONBOARDED=1 SIMCTL_CHILD_PD_TAB=stats
    let launchDetailPaper: Paper?
    let launchTranslated: Bool
    /// PD_REVIEW=1 — 상세 진입 직후 리뷰 리더 자동 푸시 (1회 소비).
    private var launchShowReviewPending: Bool
    /// PD_REVIEW_SEC=<n> — 리더 로드 후 해당 섹션으로 자동 스크롤 (상태 B 캡처용).
    let launchReviewSection: Int?

    func consumeLaunchReview() -> Bool {
        guard launchShowReviewPending else { return false }
        launchShowReviewPending = false
        return true
    }
    /// PD_REVIEW_SAMPLE 훅 — 피드 교체(원격 로드/폴백) 후에도 첫 논문에 재부착한다.
    private var sampleReviewURLString: String? = nil

    private func applySampleReviewHook() {
        guard let sample = sampleReviewURLString, !feed.isEmpty else { return }
        feed[0].reviewMarkdownURL = sample
    }

    init() {
        // Reads BOTH env vars (SIMCTL_CHILD_PD_*) and launch args (-PD_* value via
        // NSUserDefaults argument domain). The latter is the reliable path under simctl.
        let env = ProcessInfo.processInfo.environment
        let defaults = UserDefaults.standard
        func flag(_ key: String) -> Bool { env[key] == "1" || defaults.bool(forKey: key) }
        func string(_ key: String) -> String? { env[key] ?? defaults.string(forKey: key) }

        // Assign stored `let`s first — no `self` access allowed before both are set.
        launchTranslated = flag("PD_TRANSLATED")
        // PD_REVIEW(_SAMPLE) — 훅으로 여는 상세/리더에도 샘플 마크다운이 붙은 같은 Paper가 가야 함.
        let sampleReviewURL: String? = (flag("PD_REVIEW_SAMPLE") || flag("PD_REVIEW"))
            ? Bundle.main.url(forResource: "SampleReview", withExtension: "md")?.absoluteString
            : nil
        var seedFirst = SampleData.feed.first
        if let sample = sampleReviewURL { seedFirst?.reviewMarkdownURL = sample }
        launchDetailPaper = (flag("PD_DETAIL") || flag("PD_REVIEW")) ? seedFirst : nil
        launchShowReviewPending = flag("PD_REVIEW")
        launchReviewSection = string("PD_REVIEW_SEC").flatMap(Int.init)
        sampleReviewURLString = sampleReviewURL
        // Language: env/arg override → saved setting → device default. (didSet won't fire in init.)
        if let raw = string("PD_LANG"), let l = AppLanguage(rawValue: raw) { lang = l }
        else { lang = .deviceDefault }
        // Saved/read papers persist across launches. (didSet won't fire in init.)
        if let saved = defaults.stringArray(forKey: "PD_SAVED_IDS") { savedIDs = Set(saved) }
        if let read = defaults.stringArray(forKey: "PD_READ_IDS") { readIDs = Set(read) }
        // Onboarding state persists (4-4). (didSet won't fire in init.)
        if defaults.bool(forKey: "PD_ONBOARDED_DONE") { onboarded = true }
        if let saved = defaults.stringArray(forKey: "PD_INTERESTS"), !saved.isEmpty { interests = Set(saved) }
        if let raw = defaults.string(forKey: "PD_FREQUENCY"), let f = Frequency(rawValue: raw) { frequency = f }
        // Test hook: PD_INTERESTS_OVERRIDE=VLN[,Planner…] — 관심 분야 강제 (cfprefsd 레이스 없는 검증 경로)
        if let raw = string("PD_INTERESTS_OVERRIDE"), !raw.isEmpty {
            interests = Set(raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        }
        // Test hook: pre-seed a couple of saved papers (verify Saved tab wiring).
        if flag("PD_SEED_SAVED") { savedIDs = Set(SampleData.feed.prefix(2).map(\.id)) }
        // Test hook: 첫 피드 논문에 번들 리뷰 마크다운 부착 (sampleReviewURLString은 위에서 세팅됨).
        applySampleReviewHook()
        // All stored properties are now initialized → safe to touch `self`.
        if flag("PD_ONBOARDED") || launchDetailPaper != nil { onboarded = true }
        if let raw = string("PD_TAB"), !raw.isEmpty, let tab = Tab(rawValue: raw) { selectedTab = tab }
        // Skip the splash when a test/preview hook jumps straight to a screen.
        let jumpsToScreen = flag("PD_ONBOARDED") || flag("PD_DETAIL") || flag("PD_REVIEW")
            || (string("PD_TAB").map { !$0.isEmpty } ?? false)
        if jumpsToScreen { isLaunching = false }
    }

    /// Cold-start sequence: prefetch the feed while the splash animates, with a
    /// minimum on-screen time, then reveal onboarding (new) or the feed (existing).
    func runLaunchSequence() async {
        guard isLaunching else { return }
        if ProcessInfo.processInfo.environment["PD_HOLD_SPLASH"] == "1" { return }  // 테스트: 스플래시 유지
        let load = Task { await self.loadFeedIfNeeded() }
        try? await Task.sleep(nanoseconds: 1_300_000_000)   // 최소 ~1.3s 노출
        await load.value
        isLaunching = false
    }

    // MARK: Interests ↔ feed (4-1)

    /// 온보딩 칩 목록 — 실피드가 있으면 실제 카테고리(VLN/Planner…), 아니면 핸드오프의 12개 목업 토픽.
    var availableInterests: [String] {
        guard feedSource != .sample else { return SampleData.allInterests }
        var seen = Set<String>()
        let categories = (feed + feedArchive).map(\.filterCategory).filter { seen.insert($0).inserted }
        return categories.isEmpty ? SampleData.allInterests : categories
    }

    /// interests가 현재 피드의 분류와 하나도 겹치지 않으면(다른 분류 체계) 필터를 끈다 — 빈 피드 잠금 방지.
    private var effectiveInterests: Set<String>? {
        let categories = Set(feed.map(\.filterCategory))
        return categories.isDisjoint(with: interests) ? nil : interests
    }

    /// 온보딩 관심 분야가 반영된 피드 — 필터 칩·카드 리스트의 공통 출발점.
    private var interestFilteredFeed: [Paper] {
        guard let active = effectiveInterests else { return feed }
        return feed.filter { active.contains($0.filterCategory) }
    }

    var filteredFeed: [Paper] {
        activeFilter == "전체"
            ? interestFilteredFeed
            : interestFilteredFeed.filter { $0.filterCategory == activeFilter }
    }

    /// "전체" + the interest-filtered categories (design order preserved in sample mode).
    var feedFilters: [String] {
        let visible = interestFilteredFeed
        if feedSource == .sample {
            return SampleData.feedFilters.filter { f in
                f == "전체" || visible.contains { $0.filterCategory == f }
            }
        }
        var ordered = ["전체"]
        var seen = Set<String>()
        for category in visible.map(\.filterCategory) where seen.insert(category).inserted {
            ordered.append(category)
        }
        return ordered
    }

    /// 실피드 로드 후, 관심사가 피드 분류 체계와 전혀 겹치지 않으면 실제 카테고리 전체로 초기화.
    /// (목업 토픽으로 온보딩한 사용자·신규 사용자 모두 실피드 기준으로 정렬됨. didSet이 영속화.)
    private func alignInterestsWithFeed() {
        let categories = Set((feed + feedArchive).map(\.filterCategory))
        guard !categories.isEmpty, categories.isDisjoint(with: interests) else { return }
        interests = categories
    }

    /// Short status line under the feed header (offline / load failure).
    var feedStatusNote: String? {
        switch feedSource {
        case .cache:  strings.offlineNote
        case .failed: strings.loadFailNote
        default:      nil
        }
    }

    // MARK: Localized dynamic strings

    /// Feed header (localized sample by lang×frequency; remote override wins).
    var feedHeaderText: FeedHeaderText {
        if let h = feedHeader { return FeedHeaderText(date: h.date, title: h.title, subtitle: h.subtitle, hint: "") }
        return FeedHeaderText.of(lang, frequency)
    }
    func matchText(_ score: Int) -> String { "\(score)% \(strings.matchWord)" }
    func selectedText(_ count: Int) -> String {
        lang == .ko ? "\(count)개 선택됨 · \(strings.minSelect)" : "\(count) selected · \(strings.minSelect)"
    }
    func citedText(_ n: Int) -> String { lang == .ko ? "\(strings.citationsUnit) \(n)" : "\(n) \(strings.citationsUnit)" }
    func readTimeText(_ minutes: Int) -> String { lang == .ko ? "\(minutes)\(strings.minReadUnit)" : "\(minutes) \(strings.minReadUnit)" }
    func topicLabel(_ canonical: String) -> String { Topics.label(canonical, lang) }
    func tagLabel(_ tag: String) -> String { Tags.label(tag, lang) }
    func relativeDate(_ ls: LocalizedString) -> String { ls(lang) }

    // Review reader chrome (화면 6/7 — 본문은 항상 한국어, 크롬만 이중언어)
    func reviewTocText(_ n: Int) -> String { lang == .ko ? "목차 · \(n)개 섹션" : "CONTENTS · \(n) SECTIONS" }
    var reviewContinueWord: String { lang == .ko ? "이어서 읽기" : "Continue reading" }
    var reviewStartWord: String { lang == .ko ? "읽기 시작" : "Start reading" }

    // Weekly summary chrome
    var weekRangeText: String { lang == .ko ? "7월 3일 – 7월 9일" : "Jul 3 – Jul 9" }
    var streakText: String { lang == .ko ? "5일" : "5 days" }
    var highlightMetaText: String { lang == .ko ? "가장 오래 읽은 논문 · 27분" : "Longest read · 27 min" }

    // MARK: Feed loading

    /// Called once when the feed first appears.
    func loadFeedIfNeeded() async {
        guard !didInitialLoad else { return }
        didInitialLoad = true
        await refreshFeed()
    }

    /// Fetches the Mac Mini feed; falls back to cache, then sample data.
    func refreshFeed() async {
        defer { applySampleReviewHook() }   // 테스트 훅은 피드 교체 후에도 유지
        guard let url = Config.feedURL else {
            feed = SampleData.feed
            feedArchive = []
            feedHeader = nil
            feedSource = .sample
            return
        }
        isLoadingFeed = true
        defer { isLoadingFeed = false }
        do {
            let daily = try await RemotePaperService(url: url).loadDailyFeed()
            feed = daily.papers.isEmpty ? SampleData.feed : daily.papers
            feedArchive = daily.archive
            feedHeader = daily.header
            feedSource = .network
            alignInterestsWithFeed()
            if !filteredFeed.contains(where: { $0.filterCategory == activeFilter }), activeFilter != "전체" {
                activeFilter = "전체"   // stale filter no longer present → reset
            }
        } catch {
            if let cached = FeedCache.shared.load() {
                feed = cached.papers
                feedArchive = cached.archive
                feedHeader = cached.header
                feedSource = .cache
                alignInterestsWithFeed()
            } else {
                feed = SampleData.feed
                feedArchive = []
                feedHeader = nil
                feedSource = .failed(error.localizedDescription)
            }
        }
    }

    func toggleInterest(_ interest: String) {
        if interests.contains(interest) {
            // 최소 1개 유지
            if interests.count > 1 { interests.remove(interest) }
        } else {
            interests.insert(interest)
        }
        // 방금 숨겨진 카테고리를 가리키는 활성 필터는 초기화
        if activeFilter != "전체", !feedFilters.contains(activeFilter) { activeFilter = "전체" }
    }

    func isSaved(_ id: String) -> Bool { savedIDs.contains(id) }
    func toggleSaved(_ id: String) {
        if savedIDs.contains(id) { savedIDs.remove(id) } else { savedIDs.insert(id) }
    }

    func isRead(_ id: String) -> Bool { readIDs.contains(id) }
    func toggleRead(_ id: String) {
        if readIDs.contains(id) { readIDs.remove(id) } else { readIDs.insert(id) }
    }

    // MARK: Library (state-driven)

    /// Every resolvable paper — current feed first (remote picks win), then the
    /// feed archive (past batches), then the bundled catalog.
    var catalog: [Paper] {
        var seen = Set<String>()
        return (feed + feedArchive + SampleData.catalog).filter { seen.insert($0.id).inserted }
    }

    /// Rows for a tab: To-read is the seeded list; Saved/Done reflect user actions.
    func libraryItems(for tab: LibraryTab) -> [LibraryItem] {
        switch tab {
        case .toRead:
            return toReadItems
        case .saved:
            return catalog
                .filter { savedIDs.contains($0.id) }
                .map { LibraryItem(paper: $0, relativeDate: LocalizedString("오늘", "Today"), progress: nil) }
        case .done:
            return catalog
                .filter { readIDs.contains($0.id) }
                .map { LibraryItem(paper: $0, relativeDate: LocalizedString("오늘", "Today"), progress: 100) }
        }
    }

    func removeLibraryItem(_ item: LibraryItem, from tab: LibraryTab) {
        switch tab {
        case .toRead: toReadItems.removeAll { $0.id == item.id }
        case .saved:  savedIDs.remove(item.paper.id)
        case .done:   readIDs.remove(item.paper.id)
        }
    }

    func libraryEmptyMessage(for tab: LibraryTab) -> String {
        switch tab {
        case .toRead: strings.emptyToRead
        case .saved:  strings.emptySaved
        case .done:   strings.emptyDone
        }
    }
}
