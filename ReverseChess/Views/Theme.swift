import SwiftUI

/// 앱 전역 팔레트 — 인디고 + 아이스 톤
enum Theme {
    static let accent = Color(red: 0.33, green: 0.38, blue: 0.85)          // 인디고
    static let accentSoft = Color(red: 0.33, green: 0.38, blue: 0.85).opacity(0.14)
    static let coral = Color(red: 0.95, green: 0.45, blue: 0.38)           // 강조(강제 캡처 등)

    static let boardLight = Color(red: 0.91, green: 0.93, blue: 0.96)
    static let boardDark = Color(red: 0.55, green: 0.63, blue: 0.74)
    static let boardSelected = accent.opacity(0.55)
    static let boardLastMove = Color(red: 0.98, green: 0.85, blue: 0.45).opacity(0.55)

    static let pieceWhite = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let pieceBlack = Color(red: 0.13, green: 0.15, blue: 0.20)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(.systemBackground), accent.opacity(0.06)],
            startPoint: .top, endPoint: .bottom
        )
    }
}

/// 모드 카드 등에서 쓰는 둥근 컨테이너
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
            )
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardBackground()) }
}
