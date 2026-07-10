//  AppState.swift
//  Single observable store for cross-screen state (per handoff › State Management).

import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case home, library, stats, settings
    var id: String { rawValue }

    var label: String {
        switch self {
        case .home:     "홈"
        case .library:  "라이브러리"
        case .stats:    "통계"
        case .settings: "설정"
        }
    }
}

enum LibraryTab: String, CaseIterable, Identifiable {
    case toRead, saved, done
    var id: String { rawValue }

    var label: String {
        switch self {
        case .toRead: "읽을 목록"
        case .saved:  "저장됨"
        case .done:   "완료"
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

    // 저장/읽음 상태 (카드·상세 액션 → 라이브러리/통계 반영)
    @Published var savedIDs: Set<String> = []
    @Published var readIDs: Set<String> = []

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
        case .cache:  "오프라인 · 마지막으로 받은 추천"
        case .failed: "새 추천을 불러오지 못했어요 · 당겨서 새로고침"
        default:      nil
        }
    }

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
}
