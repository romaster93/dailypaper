//  SettingsView.swift
//  Screen 6 — 설정. Not detailed in the handoff (tab exists in the bar); kept
//  minimal and on-brand: adjust recommendation frequency & interests post-onboarding.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("설정")
                    .font(AppFont.serif(30, .medium))
                    .tracking(-0.6)
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 6)
                    .padding(.bottom, 24)

                // 추천 주기
                SectionLabel(text: "추천 주기")
                    .padding(.bottom, 10)
                FrequencySegment(selection: $app.frequency)
                Text(app.frequency.hint)
                    .font(AppFont.sans(13))
                    .foregroundStyle(Palette.faint2)
                    .padding(.horizontal, 2)
                    .padding(.top, 11)
                    .padding(.bottom, 26)

                // 관심 분야
                SectionLabel(text: "관심 분야")
                    .padding(.bottom, 12)
                FlowLayout(hSpacing: 10, vSpacing: 10) {
                    ForEach(SampleData.allInterests, id: \.self) { interest in
                        InterestChip(
                            title: interest,
                            selected: app.interests.contains(interest)
                        ) {
                            app.toggleInterest(interest)
                        }
                    }
                }
                .padding(.bottom, 30)

                // 계정 / 정보
                VStack(spacing: 0) {
                    settingsRow(title: "알림", value: freqNotice)
                    Divider().background(Palette.divider)
                    settingsRow(title: "번역 언어", value: "한국어")
                    Divider().background(Palette.divider)
                    settingsRow(title: "논문 소스", value: "arXiv · Semantic Scholar")
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
                    Text("온보딩 다시 보기")
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
        case .daily:   "매일 아침"
        case .weekly:  "매주 월요일"
        case .monthly: "매달 1일"
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
