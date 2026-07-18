//  ReviewReaderView.swift
//  화면 6/7 — 에이전트 리뷰 네이티브 리더 (WKWebView 대체).
//  전처리된 리뷰 마크다운(paper.reviewMarkdownURL)을 받아 MarkdownUI로 렌더하고,
//  수식은 SwiftMath(KaTeX 상당)로, 파싱 실패 시 코드체 폴백으로 그린다.
//  상태 A: 칩 → 단일 H1 + mono 부제 → 출판 정보 카드 → 목차 카드 → 하단 CTA.
//  상태 B: 고정 리딩 헤더(현재 섹션 + % + 3px 진행 바) → 본문 → 섹션 이전/다음 네비.
//  읽기 위치(섹션+%)는 UserDefaults로 저장/복원. 콘텐츠 계약: REVIEW-FORMAT.md.

import SwiftUI
import MarkdownUI
import SwiftMath

// MARK: - Parsed document

struct ReviewDocument {
    struct Section: Identifiable {
        let id: Int
        let num: String        // "1" · "A" · 순번
        let title: String      // "개요 (Overview)"
        let label: String      // "1. 개요" — 리딩 헤더/네비용 (괄호 꼬리 제거)
        let blocks: [Block]
    }
    /// 마크다운 조각 또는 디스플레이 수식($$...$$).
    enum Block: Identifiable {
        case markdown(String)
        case math(String)
        var id: String {
            switch self {
            case .markdown(let s): "md-\(s.hashValue)"
            case .math(let s): "eq-\(s.hashValue)"
            }
        }
    }
    let title: String
    let subtitle: String?              // H1의 영문 괄호 꼬리 → UPPERCASE
    let pubRows: [(key: String, value: String)]
    let preamble: [Block]              // H1 뒤 ~ 첫 ## 전
    let sections: [Section]
    let sizeKB: Int

    // MARK: Parsing (생성기 decorateReviewBody와 같은 규칙)

    static func parse(_ raw: String) -> ReviewDocument {
        let sizeKB = max(1, raw.utf8.count / 1024)

        // H1 → title / subtitle
        var title = ""
        var subtitle: String? = nil
        if let m = raw.range(of: #"(?m)^#\s+(.+)$"#, options: .regularExpression) {
            title = String(raw[m]).replacingOccurrences(of: #"^#\s+"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: "**", with: "")
            if let pm = title.range(of: #"\s*\(([^()]+)\)\s*$"#, options: .regularExpression) {
                let inner = String(title[pm]).trimmingCharacters(in: CharacterSet(charactersIn: " ()"))
                if inner.allSatisfy({ $0.isASCII }) && !inner.isEmpty {
                    title.removeSubrange(pm)
                    subtitle = inner.uppercased()
                }
            }
        }

        // 섹션 분할: "## " 시작 줄 기준 (### 제외)
        var preambleLines: [String] = []
        var sections: [Section] = []
        var currentTitle: String? = nil
        var currentLines: [String] = []
        var sawH1 = false

        func flushSection() {
            guard let heading = currentTitle else { return }
            let i = sections.count
            let text = heading.replacingOccurrences(of: "**", with: "")
            let numbered = text.range(of: #"^\d+\."#, options: .regularExpression) != nil
            let num: String
            if numbered {
                num = String(text.prefix(while: { $0 != "." }))
            } else if let a = text.range(of: #"^부록\s*([A-Z가-힣])"#, options: .regularExpression) {
                num = String(String(text[a]).last!)
            } else {
                num = "\(i + 1)"
            }
            let secTitle = text.replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
            let short = secTitle.replacingOccurrences(of: #"\s*\([^()]*\)\s*$"#, with: "", options: .regularExpression)
            sections.append(Section(
                id: i, num: num, title: secTitle,
                label: numbered ? "\(num). \(short)" : short,
                blocks: splitBlocks(currentLines.joined(separator: "\n"))
            ))
            currentLines = []
        }

        var inFence = false
        for line in raw.components(separatedBy: "\n") {
            if line.hasPrefix("```") { inFence.toggle() }
            if !inFence, !sawH1, line.hasPrefix("# ") { sawH1 = true; continue }
            if !inFence, line.hasPrefix("## "), !line.hasPrefix("###") {
                flushSection()
                currentTitle = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                continue
            }
            if currentTitle == nil { preambleLines.append(line) } else { currentLines.append(line) }
        }
        flushSection()

        // 출판 정보: 첫 섹션(개요) 안의 `- **key**: value` 불릿 → 카드 행
        let head = (preambleLines + [sections.first.map { s in
            s.blocks.compactMap { if case .markdown(let m) = $0 { return m } else { return nil } }.joined(separator: "\n")
        } ?? ""]).joined(separator: "\n")
        var pubRows: [(key: String, value: String)] = []
        let wanted = ["발표처", "arXiv", "코드", "GitHub", "프로젝트", "프로젝트 페이지", "리뷰 일자", "학회", "학회/저널"]
        if let re = try? NSRegularExpression(pattern: #"^[-*]\s+\*\*([^*]+?)\*\*\s*[::]\s*(.+)$"#, options: [.anchorsMatchLines]) {
            let ns = head as NSString
            re.enumerateMatches(in: head, range: NSRange(location: 0, length: ns.length)) { m, _, _ in
                guard let m else { return }
                var key = ns.substring(with: m.range(at: 1))
                key = key.replacingOccurrences(of: #"\s*\([^)]*\)\s*"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                guard wanted.contains(key), !pubRows.contains(where: { $0.key == key }) else { return }
                // 마크다운 링크 [text](url) → text, 볼드 제거. 마커(✅ ❌ ⏳)는 그대로.
                var value = ns.substring(with: m.range(at: 2))
                value = value.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
                    .replacingOccurrences(of: "**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if !value.isEmpty { pubRows.append((key: key, value: value)) }
            }
        }

        return ReviewDocument(
            title: title.trimmingCharacters(in: .whitespaces),
            subtitle: subtitle,
            pubRows: pubRows,
            preamble: splitBlocks(preambleLines.joined(separator: "\n")),
            sections: sections,
            sizeKB: sizeKB
        )
    }

    /// 섹션 본문 → 마크다운 조각과 $$…$$ 디스플레이 수식으로 분할 + 인라인 수식 치환.
    private static func splitBlocks(_ text: String) -> [Block] {
        var blocks: [Block] = []
        // 코드 펜스 보호를 위해 펜스 단위로 나눠 비-펜스 부분만 수식 처리
        let fenceSplit = text.components(separatedBy: "```")
        var rebuilt: [String] = []          // 짝수 인덱스 = 본문, 홀수 = 코드
        for (i, part) in fenceSplit.enumerated() {
            rebuilt.append(i % 2 == 0 ? part : "```\(part)```")
        }
        var mdBuffer = ""
        func flushMd() {
            let t = mdBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { blocks.append(.markdown(t)) }
            mdBuffer = ""
        }
        for (i, part) in rebuilt.enumerated() {
            if i % 2 == 1 { mdBuffer += part; continue }   // 코드 펜스는 그대로 통과
            // $$…$$ 디스플레이 수식 추출
            var rest = Substring(part)
            while let open = rest.range(of: "$$"), let close = rest[open.upperBound...].range(of: "$$") {
                mdBuffer += transformInlineMath(String(rest[..<open.lowerBound]))
                flushMd()
                let eq = String(rest[open.upperBound..<close.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !eq.isEmpty { blocks.append(.math(eq)) }
                rest = rest[close.upperBound...]
            }
            mdBuffer += transformInlineMath(String(rest))
        }
        flushMd()
        return blocks
    }

    /// 인라인 `$x_t$` → 이탤릭(단순 표기) 또는 인라인 코드(TeX 명령 포함) — 시안의 serif italic 트리트먼트.
    private static func transformInlineMath(_ text: String) -> String {
        guard text.contains("$"),
              let re = try? NSRegularExpression(pattern: #"\$([^$\n]+?)\$"#) else { return text }
        let ns = text as NSString
        var out = ""
        var cursor = 0
        re.enumerateMatches(in: text, range: NSRange(location: 0, length: ns.length)) { m, _, _ in
            guard let m else { return }
            let body = ns.substring(with: m.range(at: 1))
            let isTexLike = body.rangeOfCharacter(from: CharacterSet(charactersIn: #"\^{}_"#)) != nil
                || (body.count == 1 && body.first!.isLetter)
            guard isTexLike else { return }   // 통화 표기($35k)는 건드리지 않음
            out += ns.substring(with: NSRange(location: cursor, length: m.range.location - cursor))
            let hasCommand = body.contains("\\") || body.contains("{")
            out += hasCommand ? "`\(body)`" : "*\(body.replacingOccurrences(of: "_", with: "\\_"))*"
            cursor = m.range.location + m.range.length
        }
        out += ns.substring(from: cursor)
        return out
    }
}

// MARK: - SwiftMath wrapper (README 공식 래퍼 + 파싱 검증)

struct MathView: UIViewRepresentable {
    let equation: String
    var fontSize: CGFloat = 17

    static func isValid(_ latex: String) -> Bool {
        var error: NSError? = nil
        let list = MTMathListBuilder.build(fromString: latex, error: &error)
        return list != nil && error == nil
    }

    func makeUIView(context: Context) -> MTMathUILabel {
        let view = MTMathUILabel()
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }

    func updateUIView(_ view: MTMathUILabel, context: Context) {
        view.latex = equation
        view.fontSize = fontSize
        view.textAlignment = .center
        view.labelMode = .display
        view.displayErrorInline = false
        view.textColor = UIColor(Palette.ink)
        view.invalidateIntrinsicContentSize()   // intrinsicContentSize = _sizeThatFits(.zero)
    }
}

// MARK: - MarkdownUI theme (디자인 토큰 매핑)

private extension Theme {
    static let paperReview = Theme()
        .text { ForegroundColor(Palette.body); FontSize(15) }
        .strong { FontWeight(.semibold); ForegroundColor(Palette.ink) }
        .emphasis { FontStyle(.italic); FontFamily(.system(.serif)) }
        .link { ForegroundColor(Palette.accentDeep) }
        .code { FontFamilyVariant(.monospaced); FontSize(.em(0.86)); BackgroundColor(Palette.track) }
        .paragraph { cfg in
            cfg.label
                .fixedSize(horizontal: false, vertical: true)
                .relativeLineSpacing(.em(0.4))
                .markdownMargin(top: 0, bottom: 14)
        }
        .heading3 { cfg in
            cfg.label
                .markdownMargin(top: 26, bottom: 10)
                .markdownTextStyle { FontFamily(.system(.serif)); FontWeight(.medium); FontSize(18); ForegroundColor(Palette.ink) }
        }
        .heading4 { cfg in
            cfg.label
                .markdownMargin(top: 22, bottom: 8)
                .markdownTextStyle { FontFamily(.system(.serif)); FontWeight(.medium); FontSize(16); ForegroundColor(Palette.ink) }
        }
        .blockquote { cfg in
            HStack(spacing: 0) {
                Rectangle().fill(Palette.accent).frame(width: 3)
                cfg.label
                    .markdownTextStyle { ForegroundColor(Palette.secondary) }
                    .padding(.vertical, 10).padding(.horizontal, 16)
            }
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .fixedSize(horizontal: false, vertical: true)
            .markdownMargin(top: 4, bottom: 16)
        }
        .codeBlock { cfg in
            // ASCII 아키텍처 다이어그램 → 다크 블록(줄바꿈 금지), 일반 코드 → 라이트 카드
            let isDiagram = cfg.content.contains(where: { "│┌┐└┘├┤┬┴═║╔╗╚╝▶►◀◄".contains($0) })
            ScrollView(.horizontal, showsIndicators: false) {
                cfg.label
                    .relativeLineSpacing(.em(0.35))
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(isDiagram ? 10.5 : 12.5)
                        ForegroundColor(isDiagram ? Color(hex: "E8E1D2") : Palette.body)
                    }
                    .padding(14)
            }
            .background(isDiagram ? Color(hex: "26221B") : Color(hex: "F8F4EC"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isDiagram ? .clear : Palette.cardBorder, lineWidth: 1))
            .markdownMargin(top: 4, bottom: 18)
        }
        .table { cfg in
            ScrollView(.horizontal, showsIndicators: true) { cfg.label }
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Palette.cardBorder, lineWidth: 1))
                .markdownMargin(top: 4, bottom: 18)
        }
        .tableCell { cfg in
            cfg.label
                .markdownTextStyle {
                    if cfg.row == 0 {
                        FontFamilyVariant(.monospaced); FontSize(10.5); ForegroundColor(Palette.sectionLabel)
                    } else {
                        FontSize(13); ForegroundColor(Palette.body)
                    }
                }
                .padding(.vertical, 10).padding(.horizontal, 12)
        }
        .image { cfg in
            cfg.label
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .markdownMargin(top: 8, bottom: 16)
        }
}

// MARK: - Scroll tracking preferences

private struct SectionTopsKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private struct ScrollMetricsKey: PreferenceKey {
    static var defaultValue: [CGFloat] = []
    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - Reader

struct ReviewReaderView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    let paper: Paper
    let markdownURL: URL

    @State private var doc: ReviewDocument?
    @State private var loadFailed = false
    @State private var currentSection = -1
    @State private var progress: Double = 0        // 0…1 전체 진행률
    @State private var reading = false             // 상태 B (리딩 헤더 표시)
    @State private var restored = false

    private var posKey: String { "PD_REVIEW_POS_\(paper.id)" }
    private var savedPos: (section: Int, pct: Int)? {
        guard let d = UserDefaults.standard.dictionary(forKey: posKey),
              let s = d["section"] as? Int, let p = d["pct"] as? Int else { return nil }
        return (s, p)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            content
        }
        .background(Palette.appBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await load() }
        .onDisappear { savePosition() }
        .onChange(of: currentSection) { savePosition() }                      // 섹션 이동 시마다 저장
        .onChange(of: Int(progress * 20)) { savePosition() }                  // 5% 단위 디바운스 저장 (강제 종료 대비)
    }

    /// 웹 리뷰 페이지가 있으면 그것을 공유, 아니면 원격 마크다운 URL (file://는 공유 제외).
    private var shareURL: URL? {
        if let s = paper.reviewURL.flatMap(URL.init(string:)) { return s }
        return markdownURL.isFileURL ? nil : markdownURL
    }

    // 상단 바: ← 뒤로 · 공유 (arXiv 링크는 피드 필드 추가 후)
    private var topBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Text("←").font(AppFont.sans(15, .semibold)).foregroundStyle(Palette.muted)
            }
            .buttonStyle(.plain)
            Spacer()
            if let share = shareURL {
                ShareLink(item: share) {
                    Text(app.strings.detailShare).font(AppFont.sans(14, .medium)).foregroundStyle(Palette.accentDeep)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 46)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var content: some View {
        if let doc {
            reader(doc)
        } else if loadFailed {
            VStack(spacing: 18) {
                Text(app.strings.reviewLoadFail).font(AppFont.sans(14)).foregroundStyle(Palette.muted)
                OutlineButton(title: app.strings.reviewRetry, height: 44, radius: 12) {
                    loadFailed = false
                    Task { await load() }
                }
                .frame(width: 160)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ProgressView().tint(Palette.accentDeep).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func reader(_ doc: ReviewDocument) -> some View {
        GeometryReader { outer in
            ScrollViewReader { proxy in
                ZStack(alignment: .bottom) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            docHead(doc, proxy: proxy)
                                .id("doc-top")
                            ForEach(doc.sections) { section in
                                sectionView(section, of: doc, proxy: proxy)
                            }
                            footer
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                        .background(GeometryReader { g in
                            Color.clear.preference(
                                key: ScrollMetricsKey.self,
                                value: [g.frame(in: .named("reviewScroll")).minY, g.size.height]
                            )
                        })
                    }
                    .coordinateSpace(name: "reviewScroll")
                    .onPreferenceChange(ScrollMetricsKey.self) { v in
                        guard v.count >= 2 else { return }
                        let offset = -v[0], contentH = v[1]
                        let denom = max(1, contentH - outer.size.height)
                        progress = min(1, max(0, offset / denom))
                    }
                    .onPreferenceChange(SectionTopsKey.self) { tops in
                        let visible = tops.filter { $0.value <= 90 }
                        currentSection = visible.keys.max() ?? -1
                        withAnimation(.easeInOut(duration: 0.2)) { reading = currentSection >= 0 }
                    }

                    ctaBar(doc, proxy: proxy)
                }
                .overlay(alignment: .top) { readingHeader(proxy: proxy) }
                .onAppear {
                    // PD_REVIEW_SEC=<n> — 상태 B 캡처용 자동 스크롤 (테스트 훅)
                    if let n = app.launchReviewSection, n >= 0, n < doc.sections.count {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo("sec-\(n)", anchor: .top) }
                        }
                    }
                }
            }
        }
    }

    // MARK: 상태 A — 문서 상단

    private func docHead(_ doc: ReviewDocument, proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(paper.filterCategory)
                    .font(AppFont.mono(11, .medium)).foregroundStyle(Palette.accentDeep)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Palette.accentSoftBg, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text(slug)
                    .font(AppFont.mono(11)).foregroundStyle(Palette.tagText)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Palette.track, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .lineLimit(1)
            }
            .padding(.bottom, 14)

            Text(doc.title)
                .font(AppFont.serif(25, .medium))
                .tracking(-0.5)
                .foregroundStyle(Palette.ink)
                .lineHeight(1.28, fontSize: 25)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 8)

            if let sub = doc.subtitle {
                Text(sub)
                    .font(AppFont.mono(11)).tracking(0.66)
                    .foregroundStyle(Palette.sectionLabel)
                    .padding(.bottom, 18)
            }

            pubCard(doc).padding(.bottom, 14)
            tocCard(doc, proxy: proxy).padding(.bottom, 8)
        }
        .padding(.top, 6)
    }

    private func pubCard(_ doc: ReviewDocument) -> some View {
        VStack(spacing: 0) {
            let rows = doc.pubRows + [(key: "분량", value: "\(doc.sizeKB)KB · 약 \(paper.readMinutes)분 읽기")]
            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                HStack(alignment: .top, spacing: 12) {
                    Text(row.key)
                        .font(AppFont.mono(11)).foregroundStyle(Palette.sectionLabel)
                        .frame(width: 64, alignment: .leading)
                        .padding(.top, 2)
                    Text(row.value)
                        .font(AppFont.sans(13.5))
                        .foregroundStyle(row.key == "arXiv" ? Palette.accentDeep : Palette.body)
                        .fontWeight(row.key == "arXiv" ? .semibold : .regular)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 11)
                if i < rows.count - 1 {
                    Rectangle().fill(Palette.divider).frame(height: 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.cardBorder, lineWidth: 1))
    }

    private func tocCard(_ doc: ReviewDocument, proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(app.reviewTocText(doc.sections.count))
                .font(AppFont.mono(11)).tracking(0.88)
                .foregroundStyle(Palette.sectionLabel)
                .padding(.bottom, 5)
            ForEach(doc.sections) { s in
                let current = s.id == currentSection
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo("sec-\(s.id)", anchor: .top) }
                } label: {
                    HStack(spacing: 10) {
                        Text(s.num)
                            .font(AppFont.mono(11, current ? .medium : .regular))
                            .foregroundStyle(current ? Palette.accentDeep : Palette.sectionLabel)
                            .frame(width: 22, alignment: .leading)
                        Text(s.title)
                            .font(AppFont.sans(14, current ? .semibold : .regular))
                            .foregroundStyle(current ? Palette.accentDeep : Palette.body)
                            .lineLimit(1)
                        Spacer()
                        if current {
                            Text("\(Int(progress * 100))%")
                                .font(AppFont.mono(11)).foregroundStyle(Palette.accentDeep)
                        }
                    }
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if s.id < doc.sections.count - 1 {
                    Rectangle().fill(Palette.divider).frame(height: 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.cardBorder, lineWidth: 1))
    }

    // MARK: 상태 B — 본문 섹션

    private func sectionView(_ section: ReviewDocument.Section, of doc: ReviewDocument, proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // H2 — Newsreader 22, 하단 구분선
            Text(section.title)
                .font(AppFont.serif(22, .medium))
                .tracking(-0.22)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 34)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) { Rectangle().fill(Palette.divider).frame(height: 1) }
                .padding(.bottom, 14)
                .id("sec-\(section.id)")
                .background(GeometryReader { g in
                    Color.clear.preference(
                        key: SectionTopsKey.self,
                        value: [section.id: g.frame(in: .named("reviewScroll")).minY]
                    )
                })

            ForEach(section.blocks) { block in
                switch block {
                case .markdown(let md):
                    Markdown(md)
                        .markdownTheme(.paperReview)
                case .math(let eq):
                    if MathView.isValid(eq) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            MathView(equation: eq)
                                .padding(.vertical, 16).padding(.horizontal, 14)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.cardBorder, lineWidth: 1))
                        .padding(.vertical, 8)
                    } else {
                        // 유사 표기 — 시안의 serif italic 폴백
                        Text(eq)
                            .font(AppFont.serif(15, .regular)).italic()
                            .foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16).padding(.horizontal, 14)
                            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.cardBorder, lineWidth: 1))
                            .padding(.vertical, 8)
                    }
                }
            }

            // 섹션 이전/다음 네비게이션
            HStack {
                if section.id > 0 {
                    let prev = doc.sections[section.id - 1]
                    Button { withAnimation { proxy.scrollTo("sec-\(prev.id)", anchor: .top) } } label: {
                        Text("← \(prev.label)").font(AppFont.sans(13, .semibold)).foregroundStyle(Palette.accentDeep).lineLimit(1)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                if section.id < doc.sections.count - 1 {
                    let next = doc.sections[section.id + 1]
                    Button { withAnimation { proxy.scrollTo("sec-\(next.id)", anchor: .top) } } label: {
                        Text("\(next.label) →").font(AppFont.sans(13, .semibold)).foregroundStyle(Palette.accentDeep).lineLimit(1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 16)
            .overlay(alignment: .top) { Rectangle().fill(Palette.border).frame(height: 1) }
            .padding(.top, 18)
        }
    }

    private var footer: some View {
        Text("PaperDaily · 자동 생성 리뷰")
            .font(AppFont.mono(11)).tracking(0.88)
            .foregroundStyle(Palette.sectionLabel)
            .frame(maxWidth: .infinity)
            .padding(.top, 30)
    }

    // MARK: 고정 리딩 헤더 (상태 B)

    @ViewBuilder
    private func readingHeader(proxy: ScrollViewProxy) -> some View {
        if reading, let doc, currentSection >= 0, currentSection < doc.sections.count {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button {
                        savePosition()
                        withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo("doc-top", anchor: .top) }
                    } label: {
                        Text("‹").font(AppFont.sans(17, .semibold)).foregroundStyle(Palette.muted)
                    }
                    .buttonStyle(.plain)
                    Text(doc.sections[currentSection].label)
                        .font(AppFont.mono(11.5)).foregroundStyle(Palette.secondary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(AppFont.mono(11)).foregroundStyle(Palette.accentDeep)
                }
                .frame(height: 44)
                .padding(.horizontal, 24)
                ProgressTrack(value: progress, height: 3)
                    .clipShape(Rectangle())
            }
            .background(Palette.appBg)
            .overlay(alignment: .bottom) { Rectangle().fill(Palette.border).frame(height: 1) }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: 하단 CTA (상태 A)

    @ViewBuilder
    private func ctaBar(_ doc: ReviewDocument, proxy: ScrollViewProxy) -> some View {
        if !reading {
            VStack {
                PrimaryButton(title: ctaTitle) {
                    let target: Int
                    if let saved = savedPos, saved.section >= 0, saved.section < doc.sections.count, saved.pct >= 3, saved.pct < 99 {
                        target = saved.section
                    } else {
                        target = 0
                    }
                    withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo("sec-\(target)", anchor: .top) }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)
            .background(
                LinearGradient(
                    colors: [Palette.appBg, Palette.appBg, Palette.appBg.opacity(0)],
                    startPoint: .bottom, endPoint: .top
                )
                .ignoresSafeArea(edges: .bottom)
            )
            .transition(.opacity)
        }
    }

    private var ctaTitle: String {
        if let saved = savedPos, saved.pct >= 3, saved.pct < 99 {
            return "\(app.reviewContinueWord) · \(saved.pct)%"
        }
        return app.reviewStartWord
    }

    // MARK: Helpers

    /// 리뷰 폴더 슬러그 (…/reviews/<slug>/… 의 폴더명; 번들 파일이면 파일명)
    private var slug: String {
        if markdownURL.isFileURL { return markdownURL.deletingPathExtension().lastPathComponent }
        let name = (paper.reviewURL.flatMap(URL.init(string:)) ?? markdownURL).deletingLastPathComponent().lastPathComponent
        return name.isEmpty || name == "/" ? markdownURL.deletingPathExtension().lastPathComponent : name
    }

    private func savePosition() {
        guard doc != nil else { return }
        let pct = Int((progress * 100).rounded())
        UserDefaults.standard.set(["section": max(0, currentSection), "pct": pct], forKey: posKey)
    }

    private func load() async {
        do {
            let data: Data
            if markdownURL.isFileURL {
                data = try Data(contentsOf: markdownURL)
            } else {
                let (d, response) = try await URLSession.shared.data(from: markdownURL)
                if let http = response as? HTTPURLResponse, http.statusCode >= 400 { throw URLError(.badServerResponse) }
                data = d
            }
            guard let text = String(data: data, encoding: .utf8) else { throw URLError(.cannotDecodeContentData) }
            doc = ReviewDocument.parse(text)
        } catch {
            loadFailed = true
        }
    }
}
