//  OnboardingView.swift
//  Screen 1 — 관심 분야 설정. Progress → heading → frequency segment → interest chips → CTA.

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.appBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // 진행 표시 02 / 03 + 66% 바
                    HStack(spacing: 12) {
                        Text("02 / 03")
                            .font(AppFont.mono(12))
                            .foregroundStyle(Palette.sectionLabel)
                        ProgressTrack(value: 0.66, height: 4)
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 30)

                    Text("어떤 분야를\n관심 있게 보시나요?")
                        .font(AppFont.serif(30, .medium))
                        .tracking(-0.6)
                        .foregroundStyle(Palette.ink)
                        .lineHeight(1.22, fontSize: 30)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 12)

                    Text("관심 분야와 추천 주기를 고르면, 그에 맞춰 논문을 골라 드려요. 언제든 다시 바꿀 수 있어요.")
                        .font(AppFont.sans(14.5))
                        .foregroundStyle(Palette.muted)
                        .lineHeight(1.55, fontSize: 14.5)
                        .fixedSize(horizontal: false, vertical: true)
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
                }
                .padding(.horizontal, 26)
                .padding(.top, 8)
                .padding(.bottom, 150)
            }

            ctaBar
        }
    }

    private var ctaBar: some View {
        VStack(spacing: 11) {
            Text("\(app.interests.count)개 선택됨 · 최소 1개")
                .font(AppFont.mono(12))
                .foregroundStyle(Palette.faint2)
                .frame(maxWidth: .infinity)

            PrimaryButton(title: "다음") {
                app.onboarded = true
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [Palette.appBg, Palette.appBg, Palette.appBg.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Frequency segmented control (3분할, 활성 = white pill)

struct FrequencySegment: View {
    @Binding var selection: Frequency
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Frequency.allCases) { freq in
                let active = selection == freq
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = freq }
                } label: {
                    Text(freq.label)
                        .font(AppFont.sans(14, .semibold))
                        .foregroundStyle(active ? Palette.ink : Palette.tagText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if active {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Palette.surface)
                                    .shadow(color: Color(hex: "281E14").opacity(0.10), radius: 1, x: 0, y: 1)
                                    .matchedGeometryEffect(id: "seg", in: ns)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Palette.track, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Interest chip

struct InterestChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                if selected {
                    Text("✓")
                }
            }
            .font(AppFont.sans(14.5, selected ? .semibold : .regular))
            .foregroundStyle(selected ? Palette.accentDeep : Palette.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                selected ? Palette.accentSoftBg : Palette.surface,
                in: Capsule()
            )
            .overlay(
                Capsule().strokeBorder(
                    selected ? Palette.accentSoftBorder : Palette.border,
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
    }
}
