//  WeeklySummaryView.swift
//  Screen 5 — 이번 주 요약. Stat cards → topic distribution → highlight.

import SwiftUI

struct WeeklySummaryView: View {
    @EnvironmentObject var app: AppState
    private let stats = SampleData.weekly

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text(app.weekRangeText)
                    .font(AppFont.mono(12))
                    .tracking(0.48)
                    .foregroundStyle(Palette.accentDeep)
                    .padding(.bottom, 8)
                Text(app.strings.weekTitle)
                    .font(AppFont.serif(30, .medium))
                    .tracking(-0.6)
                    .foregroundStyle(Palette.ink)
                    .padding(.bottom, 20)

                // 통계 카드 3개
                HStack(spacing: 11) {
                    StatCard(number: "\(stats.read)", label: app.strings.statRead, accent: false)
                    StatCard(number: "\(stats.saved)", label: app.strings.statSaved, accent: false)
                    StatCard(number: app.streakText, label: app.strings.statStreak, accent: true)
                }
                .padding(.bottom, 28)

                // 주제 분포
                SectionLabel(text: app.strings.topicDist)
                    .padding(.bottom, 16)
                VStack(spacing: 14) {
                    ForEach(stats.topics) { topic in
                        HStack(spacing: 12) {
                            Text(app.topicLabel(topic.label))
                                .font(AppFont.sans(13))
                                .foregroundStyle(Palette.body)
                                .frame(width: 72, alignment: .leading)
                            ProgressTrack(value: Double(topic.percent) / 100, height: 10, fillOpacity: topic.opacity)
                            Text("\(topic.percent)%")
                                .font(AppFont.mono(11))
                                .foregroundStyle(Palette.tagText)
                                .frame(width: 32, alignment: .trailing)
                        }
                    }
                }
                .padding(.bottom, 30)

                // 이번 주 하이라이트
                SectionLabel(text: app.strings.highlightLabel)
                    .padding(.bottom, 14)
                VStack(alignment: .leading, spacing: 0) {
                    Text(app.highlightMetaText)
                        .font(AppFont.mono(11))
                        .foregroundStyle(Palette.tagText)
                        .padding(.bottom, 8)
                    Text(stats.highlight.title)
                        .font(AppFont.serif(18, .medium))
                        .foregroundStyle(Palette.ink)
                        .lineHeight(1.3, fontSize: 18)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 6)
                    Text(stats.highlight.meta)
                        .font(AppFont.sans(13))
                        .foregroundStyle(Palette.muted)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Palette.cardBorder, lineWidth: 1)
                )
            }
            .padding(.horizontal, 26)
            .padding(.top, 8)
            .padding(.bottom, 104)
        }
    }
}

// MARK: - Stat card

struct StatCard: View {
    let number: String
    let label: String
    let accent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(number)
                .font(AppFont.serif(30, .medium))
                .foregroundStyle(accent ? .white : Palette.ink)
            Text(label)
                .font(AppFont.mono(11))
                .foregroundStyle(accent ? Palette.statOnAccent : Palette.tagText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(
            accent ? Palette.accent : Palette.surface,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(accent ? .clear : Palette.cardBorder, lineWidth: 1)
        )
    }
}
