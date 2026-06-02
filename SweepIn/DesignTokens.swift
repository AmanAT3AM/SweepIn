//
//  DesignTokens.swift
//  SweepIn
//
//  Created by apple on 26/04/26.
//


import SwiftUI

//  - Color Palette
extension Color {
    // Blues
    static let sky       = Color(hex: "#1A6FF4")   // primary
    static let sky2      = Color(hex: "#3D8BFF")
    static let sky3      = Color(hex: "#E8F1FF")   // light blue bg
    static let sky4      = Color(hex: "#C8DCFF")   // border
    static let sky5      = Color(hex: "#F0F6FF")   // lightest

    // Accents
    static let coral     = Color(hex: "#FF5C3E")   // promo red
    static let coral2    = Color(hex: "#FFF0ED")
//    static let danger    = Color(hex: "#DC2626")
    static let mint      = Color(hex: "#00C48C")   // success green
    static let mint2     = Color(hex: "#E6FAF4")
    static let gold      = Color(hex: "#F59E0B")   // stars
    static let gold2     = Color(hex: "#FFFBEB")

    // Neutrals
    static let ink       = Color(hex: "#0F1923")   // primary text
    static let ink2      = Color(hex: "#1E2D3D")
    static let stone     = Color(hex: "#5B6F82")   // secondary text
    static let stone2    = Color(hex: "#8FA3B5")   // tertiary text
    static let fog       = Color(hex: "#C8D6E2")   // disabled / borders
    static let fog2      = Color(hex: "#E4EDF4")   // light borders
    static let paper     = Color(hex: "#F4F8FC")   // background
    static let appBG     = Color(hex: "#EDF3F8")   // outer bg

    // Gradient stops
    static let gradBlue1 = Color(hex: "#0D4FBE")
    static let gradBlue2 = Color(hex: "#1A6FF4")
    static let gradBlue3 = Color(hex: "#2E8BFF")
    static let gradDark1 = Color(hex: "#0B44AF")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a,r,g,b) = (255,(int>>8)*17,(int>>4&0xF)*17,(int&0xF)*17)
        case 6: (a,r,g,b) = (255,int>>16,int>>8&0xFF,int&0xFF)
        case 8: (a,r,g,b) = (int>>24,int>>16&0xFF,int>>8&0xFF,int&0xFF)
        default: (a,r,g,b) = (1,1,1,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Typography  (Plus Jakarta Sans + Sora)
struct CleanlyFont {
    // Display / headings → Sora
    static func sora(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("Sora", size: size).weight(weight)
    }
    // Body → Plus Jakarta Sans
    static func jakarta(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("PlusJakartaSans", size: size).weight(weight)
    }
}

//  - Shadows
extension View {
    func shadowSm() -> some View {
        self.shadow(color: Color.sky.opacity(0.08), radius: 6, x: 0, y: 2)
    }
    func shadowMd() -> some View {
        self.shadow(color: Color.ink.opacity(0.10), radius: 16, x: 0, y: 8)
    }
    func shadowBlue() -> some View {
        self.shadow(color: Color.sky.opacity(0.18), radius: 12, x: 0, y: 8)
    }
}

//  - Gradient Helpers
extension LinearGradient {
    static let splashBG = LinearGradient(
        colors: [Color.gradBlue1, Color.gradBlue2, Color.gradBlue3],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let headerBG = LinearGradient(
        colors: [Color.gradDark1, Color.sky],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let promoBG = LinearGradient(
        colors: [Color.coral, Color(hex: "#FF8A72")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let serviceHeroBG = LinearGradient(
        colors: [Color.sky5, Color.sky3],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
