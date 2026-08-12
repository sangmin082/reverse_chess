import SwiftUI

/// 체스판 렌더링 + 터치 입력.
/// 표시 방향: 흑이 아래 (플레이어 진영), 백이 위 — rank 8이 화면 아래쪽.
struct BoardView: View {
    let board: Board
    let lastMove: Move?
    let selected: Square?
    let targets: Set<Square>
    /// 강제 캡처 대상 칸 (악센트 링으로 표시)
    let forcedTargets: Set<Square>
    let onTap: (Square) -> Void

    var body: some View {
        GeometryReader { geo in
            let size = geo.size.width / 8
            ZStack(alignment: .topLeading) {
                ForEach(0..<64, id: \.self) { sq in
                    squareView(sq, size: size)
                        .frame(width: size, height: size)
                        .offset(
                            x: CGFloat(SquareUtil.file(sq)) * size,
                            // 흑이 아래: rank 7(흑 진영)이 y 최대 → 아래쪽
                            y: CGFloat(SquareUtil.rank(sq)) * size
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.width, alignment: .topLeading)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(Theme.ink, lineWidth: 2)
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

            // 좌표 라벨: a열에 랭크 숫자, 화면 맨 아래 줄(rank 8)에 파일 문자
            if SquareUtil.file(sq) == 0 || SquareUtil.rank(sq) == 7 {
                coordinateLabel(sq, size: size, isDark: isDark)
            }

            if let piece = board[sq] {
                Text(piece.glyph)
                    .font(.system(size: size * 0.76))
                    .foregroundStyle(piece.color == .white ? Theme.pieceWhite : Theme.pieceBlack)
                    .shadow(
                        color: Theme.ink.opacity(piece.color == .white ? 0.55 : 0),
                        radius: 0.8, y: 0.8
                    )
                    .minimumScaleFactor(0.5)
            }

            if targets.contains(sq) {
                if board[sq] != nil {
                    // 캡처 타깃: 링 (강제 캡처는 악센트색)
                    Rectangle()
                        .strokeBorder(
                            forcedTargets.contains(sq) ? Theme.accent : Theme.ink,
                            lineWidth: size * 0.07
                        )
                } else {
                    Circle()
                        .fill(Theme.ink.opacity(0.4))
                        .frame(width: size * 0.26, height: size * 0.26)
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
                        .font(.system(size: size * 0.2, weight: .semibold))
                        .foregroundStyle(color)
                        .padding(2)
                }
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                if SquareUtil.rank(sq) == 7 {
                    Text(files[SquareUtil.file(sq)])
                        .font(.system(size: size * 0.2, weight: .semibold))
                        .foregroundStyle(color)
                        .padding(2)
                }
            }
        }
    }
}
