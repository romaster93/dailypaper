//  FeedView.swift
//  Screen 2 — 추천 피드. Header (frequency-linked) → filter chips → paper cards.

import SwiftUI

struct FeedView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // 헤더 (원격 헤더 우선, 없으면 추천 주기 연동)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Text(app.feedHeaderText.date)
                            .font(AppFont.mono(12))
                            .tracking(0.48)
                            .foregroundStyle(Palette.accentDeep)
                        if app.isLoadingFeed {
                            ProgressView()
                                .controlSize(.mini)
                                .tint(Palette.accentDeep)
                        }
                    }
                    .padding(.bottom, 8)
                    Text(app.feedHeaderText.title)
                        .font(AppFont.serif(30, .medium))
                        .tracking(-0.6)
                        .foregroundStyle(Palette.ink)
                        .padding(.bottom, 6)
                    Text(app.feedHeaderText.subtitle)
                        .font(AppFont.sans(14))
                        .foregroundStyle(Palette.muted)
                    if let note = app.feedStatusNote {
                        Text(note)
                            .font(AppFont.mono(11))
                            .foregroundStyle(Palette.faint2)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 16)

                // 필터 칩 (가로 스크롤)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(app.feedFilters, id: \.self) { filter in
                            FilterChip(title: app.topicLabel(filter), active: app.activeFilter == filter) {
                                withAnimation(.easeInOut(duration: 0.22)) { app.activeFilter = filter }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 16)
                    .padding(.top, 2)
                }

                // 카드 리스트
                VStack(spacing: 15) {
                    ForEach(app.filteredFeed) { paper in
                        NavigationLink(value: paper) {
                            PaperCard(paper: paper)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.28), value: app.activeFilter)

                if app.filteredFeed.isEmpty {
                    Text(app.strings.emptyFeed)
                        .font(AppFont.sans(14))
                        .foregroundStyle(Palette.faint2)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 104)
        }
        .refreshable { await app.refreshFeed() }
        .task { await app.loadFeedIfNeeded() }
    }
}

// MARK: - Filter chip

struct FilterChip: View {
    let title: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.sans(13, active ? .semibold : .medium))
                .foregroundStyle(active ? .white : Palette.muted)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(active ? Palette.ink : Palette.surface, in: Capsule())
                .overlay(
                    Capsule().strokeBorder(active ? .clear : Palette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Paper card

struct PaperCard: View {
    @EnvironmentObject var app: AppState
    let paper: Paper

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 상단 행: 학회·언어 + 매칭 배지
            HStack {
                Text("\(paper.venue) · \(paper.feedAbstractLanguage)")
                    .font(AppFont.mono(11))
                    .foregroundStyle(Palette.tagText)
                Spacer()
                MatchBadge(text: app.matchText(paper.matchScore))
            }

            Text(paper.feedTitle)
                .font(AppFont.serif(19, .medium))
                .tracking(-0.19)
                .foregroundStyle(Palette.ink)
                .lineHeight(1.3, fontSize: 19)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 11)
                .padding(.bottom, 8)

            Text(paper.authorsShort)
                .font(AppFont.sans(13))
                .foregroundStyle(Palette.muted)
                .padding(.bottom, 9)

            Text(paper.feedAbstract)
                .font(AppFont.sans(13))
                .foregroundStyle(Palette.abstractInk)
                .lineHeight(1.55, fontSize: 13)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 13)

            HStack(spacing: 6) {
                ForEach(paper.tags, id: \.self) { PillTag(text: app.tagLabel($0)) }
            }
            .padding(.bottom, 14)

            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)
                .padding(.horizontal, -19)
                .padding(.bottom, 12)

            HStack {
                Button {
                    app.toggleSaved(paper.id)
                } label: {
                    Text(app.isSaved(paper.id) ? app.strings.saved : app.strings.save)
                        .font(AppFont.sans(13.5, .semibold))
                        .foregroundStyle(app.isSaved(paper.id) ? Palette.accentDeep : Palette.ink)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(app.strings.more)
                    .font(AppFont.sans(13.5, .semibold))
                    .foregroundStyle(Palette.accentDeep)
            }
        }
        .padding(19)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Palette.cardBorder, lineWidth: 1)
        )
        .cardShadow()
    }
}
