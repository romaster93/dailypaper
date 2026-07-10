//  Theme.swift
//  Design tokens transcribed from the "논문 데일리 (Daily Papers)" handoff.
//  Colors, typography, spacing, radii and shadows map 1:1 to the spec.

import SwiftUI
import CoreText

// MARK: - Color from hex

extension Color {
    /// Accepts "RRGGBB" or "RRGGBBAA" (with or without leading '#').
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r, g, b, a: Double
        if cleaned.count == 8 {
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        } else {
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Palette (from "Design Tokens › Colors")

enum Palette {
    static let desk          = Color(hex: "DAD4C7")   // 데스크(캔버스) 배경
    static let appBg         = Color(hex: "F4F0E8")   // 앱 배경
    static let surface       = Color(hex: "FFFFFF")   // 카드/표면

    static let ink           = Color(hex: "201C16")   // 텍스트 기본
    static let body          = Color(hex: "3F3A31")   // 본문(초록)
    static let secondary     = Color(hex: "5F5849")   // 저자/부제
    static let muted         = Color(hex: "6E675B")   // 뮤트
    static let faint         = Color(hex: "8A8375")   // 페인트 라벨
    static let faint2        = Color(hex: "948D7C")   // 페인트 라벨 2
    static let sectionLabel  = Color(hex: "A39A88")   // 섹션 라벨(mono)
    static let dateWeak      = Color(hex: "B0A997")   // 날짜/약한 mono
    static let tagText       = Color(hex: "8A8073")   // 태그 텍스트(mono)
    static let abstractInk   = Color(hex: "7A7365")   // 피드 초록 본문

    static let border        = Color(hex: "E7E0D2")   // 경계선(기본)
    static let cardBorder    = Color(hex: "EDE6D8")   // 카드 경계선
    static let divider       = Color(hex: "EFE8DB")   // 구분선
    static let track         = Color(hex: "EDE7DB")   // 트랙/태그 배경

    static let accent        = Color(hex: "C0603A")   // 액센트(테라코타)
    static let accentDeep    = Color(hex: "A34E2E")   // 액센트 딥(텍스트/링크)
    static let accentSoftBg  = Color(hex: "F4E4D7")   // 액센트 소프트 배경
    static let accentSoftBorder = Color(hex: "DDA684")// 액센트 소프트 경계선
    static let accentSoftBorder2 = Color(hex: "E4CBB9")
    static let reasonInk     = Color(hex: "6B4A38")   // 리즌 카드 본문
    static let statOnAccent  = Color(hex: "F4E0D4")   // 액센트 카드 위 라벨

    static let outlineBorder = Color(hex: "DBD3C3")   // 아웃라인 버튼 경계선
    static let tabBarBg      = Color(hex: "F4F0E8")   // 하단 탭바(0.94 opacity 적용)

    // 스플래시(실행화면)
    static let splashText    = Color(hex: "F7ECE5")   // 워드마크 · 로딩 fill
    static let splashTagline = Color(hex: "EBBFA9")   // 태그라인 · 로딩 문구
    static let splashStatus  = Color(hex: "F7E9E1")   // 밝은 상태바
}

// MARK: - Typography
//  Newsreader → serif (New York), Public Sans → default (SF), JetBrains Mono → monospaced (SF Mono).
//  Per handoff: 네이티브에서는 번들 폰트 또는 유사 시스템 폰트로 대체.

enum AppFont {
    /// Newsreader — 논문 제목, 헤딩, 통계 숫자. 대부분 weight 500(.medium).
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    /// Public Sans — UI·버튼·본문.
    static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    /// JetBrains Mono — 메타데이터, 섹션 라벨, 학회명, 날짜, 퍼센트, 배지.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Dancing Script (번들 폰트) — 스플래시 워드마크.
    static func script(_ size: CGFloat) -> Font {
        .custom("DancingScript-SemiBold", size: size)
    }

    /// Registers the bundled Dancing Script font. Call once at app launch.
    static func registerBundledFonts() {
        for name in ["DancingScript"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

// MARK: - Shadows (from "Spacing / Radius / Shadow")

extension View {
    /// 카드: 0 1px 2px rgba(40,30,20,.03), 0 14px 26px -20px rgba(40,30,20,.28)
    func cardShadow() -> some View {
        self
            .shadow(color: Color(hex: "281E14").opacity(0.03), radius: 1, x: 0, y: 1)
            .shadow(color: Color(hex: "281E14").opacity(0.16), radius: 13, x: 0, y: 10)
    }
}

// MARK: - Line-height helper
//  SwiftUI `lineSpacing` is *additional* leading; approximate CSS line-height.

extension View {
    func lineHeight(_ multiple: CGFloat, fontSize: CGFloat) -> some View {
        lineSpacing(max(0, fontSize * (multiple - 1.0) - fontSize * 0.18))
    }
}
