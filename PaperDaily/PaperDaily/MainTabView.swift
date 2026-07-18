//  MainTabView.swift
//  Custom tab container. All four tabs stay alive and cross-fade on switch (state
//  is preserved, like native tabs). A single persistent tab bar slides its active
//  dot between tabs and slides away when a paper detail is pushed (detail = no bar).

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var app: AppState
    @State private var homePath: [Paper] = []
    @State private var libraryPath: [Paper] = []
    @State private var statsPath: [Paper] = []

    /// A pushed detail (home, library or stats) means the tab bar should hide.
    private var detailShowing: Bool {
        (app.selectedTab == .home && !homePath.isEmpty) ||
        (app.selectedTab == .library && !libraryPath.isEmpty) ||
        (app.selectedTab == .stats && !statsPath.isEmpty)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.appBg.ignoresSafeArea()

            // Tab content — cross-fade between tabs, keeping each alive.
            ZStack {
                tab(homeTab, .home)
                tab(libraryTab, .library)
                tab(statsTab, .stats)
                tab(settingsTab, .settings)
            }
            .animation(.easeInOut(duration: 0.22), value: app.selectedTab)

            // Single persistent tab bar; slides down/out under a pushed detail.
            if !detailShowing {
                AppTabBar()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.28), value: detailShowing)
    }

    /// Wraps a tab with opacity + hit-testing tied to selection (cross-fade).
    private func tab<Content: View>(_ content: Content, _ which: Tab) -> some View {
        content
            .opacity(app.selectedTab == which ? 1 : 0)
            .allowsHitTesting(app.selectedTab == which)
    }

    private var homeTab: some View {
        NavigationStack(path: $homePath) {
            FeedView()
                .navigationDestination(for: Paper.self) { paper in
                    PaperDetailView(paper: paper, initialTranslated: app.launchTranslated)
                }
                .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            if let paper = app.launchDetailPaper, homePath.isEmpty { homePath = [paper] }
        }
    }

    private var libraryTab: some View {
        NavigationStack(path: $libraryPath) {
            LibraryView()
                .navigationDestination(for: Paper.self) { paper in
                    PaperDetailView(paper: paper, backLabel: app.strings.libTitle)
                }
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var statsTab: some View {
        NavigationStack(path: $statsPath) {
            WeeklySummaryView()
                .navigationDestination(for: Paper.self) { paper in
                    PaperDetailView(paper: paper, backLabel: app.strings.weekTitle)
                }
                .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            // 테스트 훅: 하이라이트 상세 자동 진입 (피드 로드 후 하이라이트가 정해지므로 task에서)
            guard app.launchStatsDetail, statsPath.isEmpty else { return }
            await app.loadFeedIfNeeded()
            if let highlight = app.weeklyHighlight { statsPath = [highlight] }
        }
    }

    private var settingsTab: some View { SettingsView() }
}
