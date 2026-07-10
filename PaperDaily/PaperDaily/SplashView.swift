//  SplashView.swift
//  Screen 0 — 실행화면(스플래시). Terracotta brand cover shown during cold-start
//  loading (recommendation prefetch / session restore), then auto-transitions to
//  onboarding (new user) or the feed (existing user).

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var app: AppState
    @State private var appeared = false     // splashIn: fade + rise + scale
    @State private var barSlid = false      // splashBar: indeterminate sweep

    var body: some View {
        ZStack {
            Palette.accent.ignoresSafeArea()   // #C0603A full-bleed background

            VStack(spacing: 0) {
                Spacer()

                // 로고 블록 (splashIn 0.7s)
                VStack(spacing: 20) {
                    Text("Daily Papers")
                        .font(AppFont.script(80))
                        .foregroundStyle(Palette.splashText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Rectangle()
                        .fill(Palette.splashText.opacity(0.5))
                        .frame(width: 54, height: 1.5)

                    Text("EXPAND YOUR INSIGHT")
                        .font(AppFont.mono(13))
                        .tracking(2.08)                 // 0.16em @ 13px
                        .foregroundStyle(Palette.splashTagline)
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.96)
                .offset(y: appeared ? 0 : 10)

                Spacer()

                // 하단 로딩 인디케이터
                VStack(spacing: 22) {
                    IndeterminateBar(slid: barSlid)
                    Text(app.strings.loading)
                        .font(AppFont.mono(11))
                        .tracking(0.88)                 // 0.08em @ 11px
                        .foregroundStyle(Palette.splashTagline)
                }
                .padding(.bottom, 66)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { appeared = true }
            barSlid = true
        }
    }
}

/// splashBar: a 46%-wide fill sweeping left→right through a 104×3 track, looping.
private struct IndeterminateBar: View {
    var slid: Bool
    private let trackW: CGFloat = 104
    private let height: CGFloat = 3
    private var barW: CGFloat { trackW * 0.46 }

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Palette.splashText.opacity(0.24))
            Capsule()
                .fill(Palette.splashText)
                .frame(width: barW)
                .offset(x: slid ? barW * 1.8 : -barW)   // translateX -100% → 180%
                .animation(.easeInOut(duration: 1.15).repeatForever(autoreverses: false), value: slid)
        }
        .frame(width: trackW, height: height)
        .clipShape(Capsule())
    }
}
