//  PaperDetailView.swift
//  Screen 3 — 논문 상세. Push view (no tab bar). Core interaction: 번역 토글.
//  A single `translated` boolean swaps title, authors, abstract, language flag,
//  abstract label and the toggle button label simultaneously (즉시 전환).

import SwiftUI

struct PaperDetailView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    let paper: Paper

    @State private var translated: Bool

    init(paper: Paper, initialTranslated: Bool = false) {
        self.paper = paper
        _translated = State(initialValue: initialTranslated)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 뒤로가기 바
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("← 오늘의 추천")
                        .font(AppFont.sans(14, .semibold))
                        .foregroundStyle(Palette.muted)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("공유")
                    .font(AppFont.sans(14, .medium))
                    .foregroundStyle(Palette.faint2)
            }
            .frame(height: 46)
            .padding(.horizontal, 24)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // 학회 라벨 + 언어 플래그
                    HStack(spacing: 8) {
                        Text(paper.venueDetail)
                            .font(AppFont.mono(11))
                            .tracking(0.44)
                            .foregroundStyle(Palette.accentDeep)
                        Text(translated ? "한국어 번역본" : "EN 원문")
                            .font(AppFont.mono(10, .medium))
                            .foregroundStyle(Palette.tagText)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Palette.track, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .padding(.bottom, 12)

                    // 제목
                    Text(paper.title(translated: translated))
                        .font(AppFont.serif(26, .medium))
                        .tracking(-0.52)
                        .foregroundStyle(Palette.ink)
                        .lineHeight(1.28, fontSize: 26)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 14)

                    // 저자
                    Text(paper.authors(translated: translated))
                        .font(AppFont.sans(14))
                        .foregroundStyle(Palette.secondary)
                        .lineHeight(1.5, fontSize: 14)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 12)

                    // 메타 행
                    HStack(spacing: 16) {
                        Text(paper.year)
                        Text("인용 \(paper.citations)")
                        Text("\(paper.readMinutes)분 읽기")
                    }
                    .font(AppFont.mono(12))
                    .foregroundStyle(Palette.tagText)
                    .padding(.bottom, 20)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Palette.border).frame(height: 1)
                    }

                    // 액션 버튼
                    HStack(spacing: 10) {
                        PrimaryButton(
                            title: app.isSaved(paper.id) ? "저장됨" : "저장하기",
                            height: 50, radius: 14
                        ) {
                            app.toggleSaved(paper.id)
                        }
                        OutlineButton(
                            title: app.isRead(paper.id) ? "읽음 ✓" : "읽음 표시",
                            height: 50, radius: 14
                        ) {
                            app.toggleRead(paper.id)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                    // 초록 섹션 헤더 + 토글
                    HStack {
                        Text(translated ? "초록 · 번역본" : "ABSTRACT")
                            .font(AppFont.mono(11))
                            .tracking(0.88)
                            .foregroundStyle(Palette.sectionLabel)
                        Spacer()
                        Button {
                            translated.toggle()
                        } label: {
                            Text(translated ? "원문 보기" : "번역본 보기")
                                .font(AppFont.sans(12.5, .semibold))
                                .foregroundStyle(Palette.accentDeep)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 6)
                                .background(Palette.accentSoftBg, in: Capsule())
                                .overlay(Capsule().strokeBorder(Palette.accentSoftBorder2, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 12)

                    // 초록 본문
                    Text(paper.abstract(translated: translated))
                        .font(AppFont.sans(14.5))
                        .foregroundStyle(Palette.body)
                        .lineHeight(1.68, fontSize: 14.5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 22)

                    // 태그
                    FlowLayout(hSpacing: 6, vSpacing: 6) {
                        ForEach(paper.detailTags, id: \.self) { PillTag(text: $0) }
                    }
                    .padding(.bottom, 22)

                    // 왜 추천했나요?
                    VStack(alignment: .leading, spacing: 8) {
                        Text("왜 추천했나요?")
                            .font(AppFont.mono(11))
                            .tracking(0.44)
                            .foregroundStyle(Palette.accentDeep)
                        Text(LocalizedStringKey(paper.reason))   // 마크다운 볼드(**...**) 렌더링
                            .font(AppFont.sans(14))
                            .foregroundStyle(Palette.reasonInk)
                            .lineHeight(1.55, fontSize: 14)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(17)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.accentSoftBg, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 26)
                .padding(.top, 6)
                .padding(.bottom, 40)
            }
        }
        .background(Palette.appBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
