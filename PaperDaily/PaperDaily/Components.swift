//  Components.swift
//  Reusable building blocks shared across screens, styled to the design tokens.

import SwiftUI

// MARK: - Flow layout (칩 그리드: flex-wrap)

struct FlowLayout: Layout {
    var hSpacing: CGFloat = 10
    var vSpacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                maxLineWidth = max(maxLineWidth, x - hSpacing)
                x = 0
                y += rowHeight + vSpacing
                rowHeight = 0
            }
            x += size.width + hSpacing
            rowHeight = max(rowHeight, size.height)
        }
        maxLineWidth = max(maxLineWidth, x - hSpacing)
        let width = maxWidth.isFinite ? maxWidth : maxLineWidth
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + vSpacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + hSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Section label (mono, uppercase-ish, letterspaced)

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(AppFont.mono(11))
            .tracking(0.88)                 // ls 0.08em @ 11px
            .foregroundStyle(Palette.sectionLabel)
    }
}

// MARK: - Pill tag (#태그, mono on track bg, radius 7)

struct PillTag: View {
    let text: String
    var fontSize: CGFloat = 11
    var body: some View {
        Text(text)
            .font(AppFont.mono(fontSize))
            .foregroundStyle(Palette.tagText)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Palette.track, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

// MARK: - Match badge (정합성 %)

struct MatchBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(AppFont.mono(11, .medium))
            .foregroundStyle(Palette.accentDeep)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Palette.accentSoftBg, in: Capsule())
    }
}

// MARK: - Progress track

struct ProgressTrack: View {
    let value: Double            // 0...1
    var height: CGFloat = 8
    var fillOpacity: Double = 1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.track)
                Capsule()
                    .fill(Palette.accent.opacity(fillOpacity))
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var height: CGFloat = 54
    var radius: CGFloat = 16
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.sans(16, .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct OutlineButton: View {
    let title: String
    var height: CGFloat = 50
    var radius: CGFloat = 14
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.sans(15, .semibold))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Palette.outlineBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bottom tab bar (custom, 활성 항목 위 5px 액센트 점)

struct AppTabBar: View {
    @EnvironmentObject var app: AppState
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                let active = app.selectedTab == tab
                Button {
                    app.selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle().fill(.clear).frame(width: 5, height: 5)
                            if active {
                                // Single dot shared across tabs → slides between them.
                                Circle().fill(Palette.accent).frame(width: 5, height: 5)
                                    .matchedGeometryEffect(id: "activeDot", in: ns)
                            }
                        }
                        Text(tab.label(app.strings))
                            .font(AppFont.sans(11, active ? .semibold : .medium))
                            .foregroundStyle(active ? Palette.ink : Palette.faint2)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: app.selectedTab)
        // Content sits just above the home indicator; the background (not the
        // content) extends into the bottom safe area. No fixed 84pt height —
        // the design's 84 already included the home-indicator space.
        .padding(.top, 12)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(
            Palette.tabBarBg.opacity(0.94)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle().fill(Palette.border).frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
