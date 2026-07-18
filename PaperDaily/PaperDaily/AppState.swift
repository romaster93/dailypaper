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

    // 온보딩
    @Published var onboarded = false
    @Published var interests: Set<String> = SampleData.defaultInterests
    @Published var frequency: Frequency = .daily

    // 네비게이션
    @Published var selectedTab: Tab = .home

    // 피드 (원격 daily.json 로드 → 없으면 샘플)
    @Published var activeFilter: String = "전체"
    @Published var feed: [Paper] = SampleData.feed
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

    init() {
        // Reads BOTH env vars (SIMCTL_CHILD_PD_*) and launch args (-PD_* value via
        // NSUserDefaults argument domain). The latter is the reliable path under simctl.
        let env = ProcessInfo.processInfo.environment
        let defaults = UserDefaults.standard
        func flag(_ key: String) -> Bool { env[key] == "1" || defaults.bool(forKey: key) }
        func string(_ key: String) -> String? { env[key] ?? defaults.string(forKey: key) }

        // Assign stored `let`s first — no `self` access allowed before both are set.
        launchTranslated = flag("PD_TRANSLATED")
        launchDetailPaper = flag("PD_DETAIL") ? SampleData.feed.first : nil
        // Language: env/arg override → saved setting → device default. (didSet won't fire in init.)
        if let raw = string("PD_LANG"), let l = AppLanguage(rawValue: raw) { lang = l }
        else { lang = .deviceDefault }
        // Saved/read papers persist across launches. (didSet won't fire in init.)
        if let saved = defaults.stringArray(forKey: "PD_SAVED_IDS") { savedIDs = Set(saved) }
        if let read = defaults.stringArray(forKey: "PD_READ_IDS") { readIDs = Set(read) }
        // Test hook: pre-seed a couple of saved papers (verify Saved tab wiring).
        if flag("PD_SEED_SAVED") { savedIDs = Set(SampleData.feed.prefix(2).map(\.id)) }
        // All stored properties are now initialized → safe to touch `self`.
        if flag("PD_ONBOARDED") || launchDetailPaper != nil { onboarded = true }
        if let raw = string("PD_TAB"), !raw.isEmpty, let tab = Tab(rawValue: raw) { selectedTab = tab }
        // Skip the splash when a test/preview hook jumps straight to a screen.
        let jumpsToScreen = flag("PD_ONBOARDED") || flag("PD_DETAIL")
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

    var filteredFeed: [Paper] {
        activeFilter == "전체"
            ? feed
            : feed.filter { $0.filterCategory == activeFilter }
    }

    /// "전체" + the distinct categories present in the feed (design order preserved in sample mode).
    var feedFilters: [String] {
        guard feedSource != .sample else { return SampleData.feedFilters }
        var ordered = ["전체"]
        var seen = Set<String>()
        for category in feed.map(\.filterCategory) where seen.insert(category).inserted {
            ordered.append(category)
        }
        return ordered.count > 1 ? ordered : SampleData.feedFilters
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
        guard let url = Config.feedURL else {
            feed = SampleData.feed
            feedHeader = nil
            feedSource = .sample
            return
        }
        isLoadingFeed = true
        defer { isLoadingFeed = false }
        do {
            let daily = try await RemotePaperService(url: url).loadDailyFeed()
            feed = daily.papers.isEmpty ? SampleData.feed : daily.papers
            feedHeader = daily.header
            feedSource = .network
            if !filteredFeed.contains(where: { $0.filterCategory == activeFilter }), activeFilter != "전체" {
                activeFilter = "전체"   // stale filter no longer present → reset
            }
        } catch {
            if let cached = FeedCache.shared.load() {
                feed = cached.papers
                feedHeader = cached.header
                feedSource = .cache
            } else {
                feed = SampleData.feed
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

    /// Every resolvable paper — current feed first (remote picks win), then the bundled catalog.
    var catalog: [Paper] {
        var seen = Set<String>()
        return (feed + SampleData.catalog).filter { seen.insert($0.id).inserted }
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
