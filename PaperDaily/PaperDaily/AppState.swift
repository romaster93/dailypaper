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
    /// 읽음 처리한 날들("yyyy-MM-dd", 기기 로컬) — 연속 일수(streak) 계산용.
    @Published private(set) var readDays: Set<String> = [] {
        didSet { UserDefaults.standard.set(Array(readDays).sorted(), forKey: "PD_READ_DAYS") }
    }
    /// 저장/읽음 시각 (논문 id → epoch 초). 라이브러리의 상대 날짜와
    /// 주간 요약의 "이번 주" 범위를 실제로 산정하기 위해 필요하다.
    @Published private(set) var savedAt: [String: Double] = [:] {
        didSet { UserDefaults.standard.set(savedAt, forKey: "PD_SAVED_AT") }
    }
    @Published private(set) var readAt: [String: Double] = [:] {
        didSet { UserDefaults.standard.set(readAt, forKey: "PD_READ_AT") }
    }

    /// 저장/읽음 시각 → 상대 날짜 문구. 시각이 없으면(이전 버전에서 저장된 항목) 빈 문자열 —
    /// 모르는 날짜를 "오늘"이라고 단정하지 않는다.
    static func relativeLabel(_ epoch: Double?) -> LocalizedString {
        guard let epoch else { return LocalizedString("", "") }
        let date = Date(timeIntervalSince1970: epoch)
        func format(_ identifier: String) -> String {
            let f = RelativeDateTimeFormatter()
            f.locale = Locale(identifier: identifier)
            f.unitsStyle = .full
            f.dateTimeStyle = .named
            return f.localizedString(for: date, relativeTo: Date())
        }
        return LocalizedString(format("ko_KR"), format("en_US"))
    }

    /// 로컬 달력 기준 날짜 키. (로케일 무관하게 고정 포맷 — 저장값 호환 유지)
    static func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
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
    /// PD_STATS_DETAIL=1 — 통계 탭의 하이라이트 논문 상세를 자동으로 push (네비게이션 검증용).
    let launchStatsDetail: Bool

    func consumeLaunchReview() -> Bool {
        guard launchShowReviewPending else { return false }
        launchShowReviewPending = false
        return true
    }
    /// PD_REVIEW_SAMPLE 훅 — 피드 교체(원격 로드/폴백) 후에도 첫 논문에 재부착한다.
    private var sampleReviewURLString: String? = nil
    /// PD_SEED_SAVED 훅 — 원격 피드 로드 후에는 실피드 논문 id로 다시 시드한다.
    private var seedSavedHook = false

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
        launchStatsDetail = flag("PD_STATS_DETAIL")
        sampleReviewURLString = sampleReviewURL
        // Language: env/arg override → saved setting → device default. (didSet won't fire in init.)
        if let raw = string("PD_LANG"), let l = AppLanguage(rawValue: raw) { lang = l }
        else { lang = .deviceDefault }
        // Saved/read papers persist across launches. (didSet won't fire in init.)
        if let saved = defaults.stringArray(forKey: "PD_SAVED_IDS") { savedIDs = Set(saved) }
        if let read = defaults.stringArray(forKey: "PD_READ_IDS") { readIDs = Set(read) }
        if let days = defaults.stringArray(forKey: "PD_READ_DAYS") { readDays = Set(days) }
        if let stamps = defaults.dictionary(forKey: "PD_SAVED_AT") as? [String: Double] { savedAt = stamps }
        if let stamps = defaults.dictionary(forKey: "PD_READ_AT") as? [String: Double] { readAt = stamps }
        // Onboarding state persists (4-4). (didSet won't fire in init.)
        if defaults.bool(forKey: "PD_ONBOARDED_DONE") { onboarded = true }
        if let saved = defaults.stringArray(forKey: "PD_INTERESTS"), !saved.isEmpty { interests = Set(saved) }
        if let raw = defaults.string(forKey: "PD_FREQUENCY"), let f = Frequency(rawValue: raw) { frequency = f }
        // Test hook: PD_INTERESTS_OVERRIDE=VLN[,Planner…] — 관심 분야 강제 (cfprefsd 레이스 없는 검증 경로)
        if let raw = string("PD_INTERESTS_OVERRIDE"), !raw.isEmpty {
            interests = Set(raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        }
        // Test hook: pre-seed a couple of saved papers (verify Saved tab wiring).
        seedSavedHook = flag("PD_SEED_SAVED")
        if seedSavedHook {
            savedIDs = Set(SampleData.feed.prefix(2).map(\.id))
            let now = Date().timeIntervalSince1970
            savedAt = Dictionary(uniqueKeysWithValues: savedIDs.map { ($0, now) })
        }
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

    /// 지금 화면에 실제 원격 피드가 떠 있는가. `.failed`는 샘플로 폴백한 상태이므로 제외해야 한다
    /// — 아니면 첫 실행 네트워크 실패 시 온보딩 칩이 샘플 카테고리로 쪼그라든다.
    var showingRemoteFeed: Bool {
        switch feedSource {
        case .network, .cache: true
        case .sample, .failed: false
        }
    }

    /// 온보딩 칩 목록 — 실피드가 있으면 실제 카테고리(VLN/Planner…), 아니면 핸드오프의 12개 목업 토픽.
    var availableInterests: [String] {
        guard showingRemoteFeed else { return SampleData.allInterests }
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
        if !showingRemoteFeed {
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

    // MARK: Weekly summary (실제 저장/읽음 상태에서 파생 — 고정 샘플 아님)

    /// 이번 주(달력 주) 범위 — "7월 3일 – 7월 9일" / "Jul 3 – Jul 9".
    var weekRangeText: String {
        let cal = Calendar.current
        guard let week = cal.dateInterval(of: .weekOfYear, for: Date()) else { return "" }
        let last = cal.date(byAdding: .day, value: -1, to: week.end) ?? week.end
        let f = DateFormatter()
        f.locale = Locale(identifier: lang == .ko ? "ko_KR" : "en_US")
        f.setLocalizedDateFormatFromTemplate("MMMd")
        return "\(f.string(from: week.start)) – \(f.string(from: last))"
    }

    var streakText: String {
        let n = streakDays
        return lang == .ko ? "\(n)일" : (n == 1 ? "1 day" : "\(n) days")
    }

    /// 하이라이트 메타 — 실제 읽기 시간은 추적하지 않으므로 리뷰 분량(예상 읽기 시간) 기준.
    func highlightMetaText(_ minutes: Int) -> String {
        lang == .ko ? "가장 긴 리뷰 · \(minutes)분 읽기" : "Longest review · \(minutes) min read"
    }

    /// "이번 주"는 화면 상단 날짜 범위와 같은 달력 주여야 한다 — 누적 전체가 아니라.
    private func inCurrentWeek(_ epoch: Double?) -> Bool {
        guard let epoch, let week = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return false }
        return week.contains(Date(timeIntervalSince1970: epoch))
    }

    /// 주간 통계의 기준 논문 — 이번 주에 저장했거나 읽은 논문 (catalog가 id 중복을 이미 제거).
    private var weeklyBasis: [Paper] {
        catalog.filter { inCurrentWeek(savedAt[$0.id]) || inCurrentWeek(readAt[$0.id]) }
    }

    var weeklyReadCount: Int { readAt.values.filter { inCurrentWeek($0) }.count }
    var weeklySavedCount: Int { savedAt.values.filter { inCurrentWeek($0) }.count }

    var hasWeeklyData: Bool { !weeklyBasis.isEmpty }

    /// 주제 분포 — 기준 논문의 카테고리 비율(상위 4개 + 나머지는 "기타").
    var weeklyTopics: [TopicShare] {
        let basis = weeklyBasis
        guard !basis.isEmpty else { return [] }
        var counts: [String: Int] = [:]
        for paper in basis { counts[paper.filterCategory, default: 0] += 1 }
        // 많은 순, 동수는 이름순 — 렌더 순서를 안정적으로 유지
        let ranked = counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
        let opacities = [1.0, 0.82, 0.64, 0.46]
        let total = Double(basis.count)
        func percent(_ n: Int) -> Int { Int((Double(n) / total * 100).rounded()) }

        var rows = ranked.prefix(4).enumerated().map { index, entry in
            TopicShare(label: entry.key, percent: percent(entry.value), opacity: opacities[index])
        }
        let rest = ranked.dropFirst(4).reduce(0) { $0 + $1.value }
        if rest > 0 {
            rows.append(TopicShare(label: "기타", percent: percent(rest), opacity: 0.46))
        }
        return rows
    }

    /// 이번 주 하이라이트 — 기준 논문 중 리뷰가 가장 긴 논문.
    var weeklyHighlight: Paper? {
        weeklyBasis
            .sorted { $0.readMinutes != $1.readMinutes ? $0.readMinutes > $1.readMinutes : $0.id < $1.id }
            .first
    }

    /// 읽기 활동이 있었던 날들로부터 계산한 연속 일수.
    /// 오늘 아직 읽지 않았으면 어제부터 세어, 하루가 완전히 지나야 끊기게 한다.
    var streakDays: Int {
        guard !readDays.isEmpty else { return 0 }
        let cal = Calendar.current
        var cursor = Date()
        if !readDays.contains(Self.dayKey(cursor)) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var count = 0
        while readDays.contains(Self.dayKey(cursor)) {
            count += 1
            guard let previous = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
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
        defer {
            applySampleReviewHook()   // 테스트 훅은 피드 교체 후에도 유지
            if seedSavedHook {   // 실피드 기준 재시드 (저장 시각도 함께)
                savedIDs = Set(feed.prefix(2).map(\.id))
                let now = Date().timeIntervalSince1970
                savedAt = Dictionary(uniqueKeysWithValues: savedIDs.map { ($0, now) })
            }
        }
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
            if let cached = FeedCache.shared.load(), !cached.papers.isEmpty {
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
        if savedIDs.contains(id) {
            savedIDs.remove(id)
            savedAt[id] = nil
        } else {
            savedIDs.insert(id)
            savedAt[id] = Date().timeIntervalSince1970
        }
    }

    func isRead(_ id: String) -> Bool { readIDs.contains(id) }
    func toggleRead(_ id: String) {
        if readIDs.contains(id) {
            readIDs.remove(id)
            readAt[id] = nil
        } else {
            readIDs.insert(id)
            readAt[id] = Date().timeIntervalSince1970
            readDays.insert(Self.dayKey(Date()))   // 연속 일수(streak) 집계
        }
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
            // 실피드 모드에서는 목업 읽을 목록 시드를 숨긴다 —
            // 리뷰 없는 가짜 논문이 실데이터와 섞여 "전체 리뷰 없음" 혼란을 만들지 않게.
            return showingRemoteFeed ? [] : toReadItems
        case .saved:
            return catalog
                .filter { savedIDs.contains($0.id) }
                .map { LibraryItem(paper: $0, relativeDate: Self.relativeLabel(savedAt[$0.id]), progress: nil) }
        case .done:
            return catalog
                .filter { readIDs.contains($0.id) }
                .map { LibraryItem(paper: $0, relativeDate: Self.relativeLabel(readAt[$0.id]), progress: 100) }
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
