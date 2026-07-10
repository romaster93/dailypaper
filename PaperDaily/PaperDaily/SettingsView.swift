//  SettingsView.swift
//  Screen 6 — 설정. Not detailed in the handoff (tab exists in the bar); kept
//  minimal and on-brand: adjust recommendation frequency & interests post-onboarding.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text(app.strings.settingsTitle)
                    .font(AppFont.serif(30, .medium))
                    .tracking(-0.6)
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 6)
                    .padding(.bottom, 24)

                // 언어
                SectionLabel(text: app.strings.langLabel)
                    .padding(.bottom, 10)
                LanguageSegment(selection: $app.lang)
                    .padding(.bottom, 26)

                // 추천 주기
                SectionLabel(text: app.strings.freqLabel)
                    .padding(.bottom, 10)
                FrequencySegment(selection: $app.frequency)
                Text(FeedHeaderText.of(app.lang, app.frequency).hint)
                    .font(AppFont.sans(13))
                    .foregroundStyle(Palette.faint2)
                    .padding(.horizontal, 2)
                    .padding(.top, 11)
                    .padding(.bottom, 26)

                // 관심 분야
                SectionLabel(text: app.strings.interestsLabel)
                    .padding(.bottom, 12)
                FlowLayout(hSpacing: 10, vSpacing: 10) {
                    ForEach(SampleData.allInterests, id: \.self) { interest in
                        InterestChip(
                            title: app.topicLabel(interest),
                            selected: app.interests.contains(interest)
                        ) {
                            app.toggleInterest(interest)
                        }
                    }
                }
                .padding(.bottom, 30)

                // 계정 / 정보
                VStack(spacing: 0) {
                    settingsRow(title: app.strings.setNotif, value: freqNotice)
                    Divider().background(Palette.divider)
                    settingsRow(title: app.strings.setTransLang, value: app.lang == .ko ? "한국어" : "Korean")
                    Divider().background(Palette.divider)
                    settingsRow(title: app.strings.setSource, value: "arXiv · Semantic Scholar")
                }
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Palette.cardBorder, lineWidth: 1)
                )
                .padding(.bottom, 24)

                Button {
                    app.onboarded = false
                } label: {
                    Text(app.strings.replayOnboarding)
                        .font(AppFont.sans(15, .semibold))
                        .foregroundStyle(Palette.accentDeep)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Palette.accentSoftBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Palette.accentSoftBorder2, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 26)
            .padding(.top, 8)
            .padding(.bottom, 104)
        }
    }

    private var freqNotice: String {
        switch app.frequency {
        case .daily:   app.strings.notifDaily
        case .weekly:  app.strings.notifWeekly
        case .monthly: app.strings.notifMonthly
        }
    }

    private func settingsRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppFont.sans(15))
                .foregroundStyle(Palette.ink)
            Spacer()
            Text(value)
                .font(AppFont.sans(13))
                .foregroundStyle(Palette.faint2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
    }
}
