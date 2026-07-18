//  LibraryView.swift
//  Screen 4 — 라이브러리. Tabs (읽을 목록 / 저장됨 / 완료) switch datasets.

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var app: AppState
    @State private var tab: LibraryTab = .toRead
    @Namespace private var tabNS

    init() {
        // Test hook: open a specific tab (e.g. SIMCTL_CHILD_PD_LIB_TAB=saved).
        let raw = ProcessInfo.processInfo.environment["PD_LIB_TAB"] ?? ""
        _tab = State(initialValue: LibraryTab(rawValue: raw) ?? .toRead)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text(app.strings.libTitle)
                    .font(AppFont.serif(30, .medium))
                    .tracking(-0.6)
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 6)
                    .padding(.bottom, 16)

                // 탭 (활성 언더라인이 슬라이드)
                HStack(spacing: 22) {
                    ForEach(LibraryTab.allCases) { t in
                        let active = tab == t
                        Button {
                            withAnimation(.easeInOut(duration: 0.24)) { tab = t }
                        } label: {
                            Text(t.label(app.strings))
                                .font(AppFont.sans(15, active ? .semibold : .medium))
                                .foregroundStyle(active ? Palette.ink : Palette.faint2)
                                .padding(.bottom, 12)
                                .overlay(alignment: .bottom) {
                                    if active {
                                        Rectangle().fill(Palette.accent).frame(height: 2)
                                            .matchedGeometryEffect(id: "libUnderline", in: tabNS)
                                    }
                                }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Palette.border).frame(height: 1)
                }
                .padding(.bottom, 20)

                // 행 리스트 (상태 연동, 탭 전환 시 페이드)
                let items = app.libraryItems(for: tab)
                if items.isEmpty {
                    Text(app.libraryEmptyMessage(for: tab))
                        .font(AppFont.sans(14))
                        .foregroundStyle(Palette.faint2)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else {
                    VStack(spacing: 12) {
                        ForEach(items) { item in
                            rowView(for: item)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: items)
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 8)
            .padding(.bottom, 104)
        }
    }

    /// 행 탭 → 논문 상세로 이동. 롱프레스 → 삭제.
    private func rowView(for item: LibraryItem) -> some View {
        NavigationLink(value: item.paper) {
            LibraryRow(item: item)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    app.removeLibraryItem(item, from: tab)
                }
            } label: {
                Label(app.strings.remove, systemImage: "trash")
            }
        }
    }
}

// MARK: - Library row

struct LibraryRow: View {
    @EnvironmentObject var app: AppState
    let item: LibraryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(item.paper.venue)
                    .font(AppFont.mono(11))
                    .foregroundStyle(Palette.tagText)
                Spacer()
                Text(app.relativeDate(item.relativeDate))
                    .font(AppFont.mono(11))
                    .foregroundStyle(Palette.dateWeak)
            }
            .padding(.bottom, 9)

            Text(item.paper.feedTitle)
                .font(AppFont.serif(16, .medium))
                .foregroundStyle(Palette.ink)
                .lineHeight(1.3, fontSize: 16)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

            HStack(spacing: 10) {
                ProgressTrack(value: Double(item.progress ?? 0) / 100, height: 8)
                // 읽음은 이진 상태다 — 측정한 적 없는 "100%" 대신 "완료"로 표기.
                Text(item.progress == 100 ? app.strings.libTab3 : (item.progress.map { "\($0)%" } ?? app.strings.notStarted))
                    .font(AppFont.mono(11))
                    .foregroundStyle(Palette.tagText)
                    .frame(minWidth: 34, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Palette.cardBorder, lineWidth: 1)
        )
    }
}
