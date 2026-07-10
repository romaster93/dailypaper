//  PaperDailyApp.swift
//  논문 데일리 (Daily Papers) — 논문 추천 리더 앱.
//  Native SwiftUI reconstruction of the high-fidelity design handoff.

import SwiftUI

@main
struct PaperDailyApp: App {
    @StateObject private var app = AppState()

    init() {
        AppFont.registerBundledFonts()   // Dancing Script (스플래시 워드마크)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .tint(Palette.accent)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack {
            Palette.appBg.ignoresSafeArea()
            if app.isLaunching {
                SplashView()
                    .transition(.opacity)
            } else if app.onboarded {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity))
            } else {
                OnboardingView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            }
        }
        .animation(.easeInOut(duration: 0.32), value: app.onboarded)
        .animation(.easeInOut(duration: 0.45), value: app.isLaunching)
        // 스플래시(어두운 배경)는 밝은 상태바, 이후는 라이트 톤 + 어두운 상태바.
        .preferredColorScheme(app.isLaunching ? .dark : .light)
        .task { await app.runLaunchSequence() }
    }
}
