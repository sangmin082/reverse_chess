import SwiftUI

/// 체스판 렌더링 + 터치 입력.
/// 표시 방향: 항상 백이 아래 (rank 1이 화면 아래쪽)
struct BoardView: View {
    let board: Board
    let lastMove: Move?
    let selected: Square?
    let targets: Set<Square>
    /// 강제 캡처 대상 칸 (코랄 링으로 표시)
    let forcedTargets: Set<Square>
    let onTap: (Square) -> Void

    var body: some View {
        GeometryReader { geo in
            let size = geo.size.width / 8
            ZStack(alignment: .bottomLeading) {
                ForEach(0..<64, id: \.self) { sq in
                    squareView(sq, size: size)
                        .frame(width: size, height: size)
                        .offset(
                            x: CGFloat(SquareUtil.file(sq)) * size,
                            y: -CGFloat(SquareUtil.rank(sq)) * size
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.width, alignment: .bottomLeading)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func squareView(_ sq: Square, size: CGFloat) -> some View {
        let isDark = (SquareUtil.file(sq) + SquareUtil.rank(sq)) % 2 == 0
        let isLast = lastMove?.from == sq || lastMove?.to == sq

        ZStack {
            Rectangle().fill(isDark ? Theme.boardDark : Theme.boardLight)
            if isLast {
                Rectangle().fill(Theme.boardLastMove)
            }
            if selected == sq {
                Rectangle().fill(Theme.boardSelected)
            }

            // 좌표 라벨 (a열과 1랭크 가장자리만)
            if SquareUtil.file(sq) == 0 || SquareUtil.rank(sq) == 0 {
                coordinateLabel(sq, size: size, isDark: isDark)
            }

            if let piece = board[sq] {
                Text(piece.glyph)
                    .font(.system(size: size * 0.74))
                    .foregroundStyle(piece.color == .white ? Theme.pieceWhite : Theme.pieceBlack)
                    .shadow(color: .black.opacity(piece.color == .white ? 0.45 : 0.2), radius: 1, y: 1)
                    .minimumScaleFactor(0.5)
            }

            if targets.contains(sq) {
                if board[sq] != nil {
                    // 캡처 타깃: 링
                    Circle()
                        .strokeBorder(
                            forcedTargets.contains(sq) ? Theme.coral : Theme.accent,
                            lineWidth: size * 0.08
                        )
                        .padding(size * 0.06)
                } else {
                    Circle()
                        .fill(Theme.accent.opacity(0.55))
                        .frame(width: size * 0.3, height: size * 0.3)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap(sq) }
    }

    private func coordinateLabel(_ sq: Square, size: CGFloat, isDark: Bool) -> some View {
        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let color = (isDark ? Theme.boardLight : Theme.boardDark).opacity(0.9)
        return VStack {
            HStack {
                if SquareUtil.file(sq) == 0 {
                    Text("\(SquareUtil.rank(sq) + 1)")
                        .font(.system(size: size * 0.2, weight: .semibold, design: .rounded))
                        .foregroundStyle(color)
                        .padding(2)
                }
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                if SquareUtil.rank(sq) == 0 {
                    Text(files[SquareUtil.file(sq)])
                        .font(.system(size: size * 0.2, weight: .semibold, design: .rounded))
                        .foregroundStyle(color)
                        .padding(2)
                }
            }
        }
    }
}
