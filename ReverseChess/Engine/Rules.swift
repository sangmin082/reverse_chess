import Foundation

/// 리버스 체스 규칙 엔진.
///
/// 규칙 요약:
/// - 흑이 선공
/// - 캐슬링·앙파상 없음, 프로모션은 있음 (퀸/룩/비숍/나이트)
/// - 체크 규칙은 기본 체스와 동일: 자기 킹을 체크에 두는 수는 둘 수 없다
/// - 강제 캡처: 잡을 수 있는 합법수가 있으면 그중 하나를 반드시 둬야 한다.
///   단, 퀸의 캡처는 체비쇼프 거리 2칸 이내일 때만 "강제" 대상이 된다
///   (2칸 초과 퀸 캡처는 강제 캡처가 없을 때 자유롭게 둘 수 있는 일반 수)
/// - 체크 회피가 강제 캡처보다 우선한다 (합법수 필터가 먼저 적용되므로 자동 충족)
enum Rules {

    // MARK: - 공격 판정

    private static let knightSteps = [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)]
    private static let kingSteps = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]
    private static let rookDirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    private static let bishopDirs = [(1, 1), (1, -1), (-1, 1), (-1, -1)]

    /// `color`가 `target` 칸을 공격하고 있는가 (체크 판정용)
    static func isAttacked(_ target: Square, by color: PieceColor, on board: Board) -> Bool {
        let tf = SquareUtil.file(target)
        let tr = SquareUtil.rank(target)

        // 폰: 백은 위로(+1), 흑은 아래로(-1) 공격
        let pawnDir = color == .white ? 1 : -1
        for df in [-1, 1] {
            let f = tf + df, r = tr - pawnDir
            if SquareUtil.isValid(file: f, rank: r),
               let p = board[SquareUtil.make(file: f, rank: r)],
               p.color == color, p.kind == .pawn { return true }
        }
        // 나이트
        for (df, dr) in knightSteps {
            let f = tf + df, r = tr + dr
            if SquareUtil.isValid(file: f, rank: r),
               let p = board[SquareUtil.make(file: f, rank: r)],
               p.color == color, p.kind == .knight { return true }
        }
        // 킹
        for (df, dr) in kingSteps {
            let f = tf + df, r = tr + dr
            if SquareUtil.isValid(file: f, rank: r),
               let p = board[SquareUtil.make(file: f, rank: r)],
               p.color == color, p.kind == .king { return true }
        }
        // 슬라이딩 (룩/퀸, 비숍/퀸)
        for (dirs, kinds) in [(rookDirs, [PieceKind.rook, .queen]), (bishopDirs, [PieceKind.bishop, .queen])] {
            for (df, dr) in dirs {
                var f = tf + df, r = tr + dr
                while SquareUtil.isValid(file: f, rank: r) {
                    if let p = board[SquareUtil.make(file: f, rank: r)] {
                        if p.color == color && kinds.contains(p.kind) { return true }
                        break
                    }
                    f += df
                    r += dr
                }
            }
        }
        return false
    }

    static func isInCheck(_ color: PieceColor, on board: Board) -> Bool {
        guard let king = board.kingSquare(of: color) else { return false }
        return isAttacked(king, by: color.opposite, on: board)
    }

    // MARK: - 수 생성

    /// 체크 규칙만 반영한 합법수 (강제 캡처 미적용)
    static func movesIgnoringForcedCapture(for color: PieceColor, on board: Board) -> [Move] {
        var moves: [Move] = []
        for (sq, piece) in board.pieces(of: color) {
            appendPseudoMoves(for: piece, at: sq, on: board, into: &moves)
        }
        return moves.filter { !isInCheck(color, on: board.applying($0)) }
    }

    /// 강제 캡처까지 반영한 최종 합법수
    static func legalMoves(for color: PieceColor, on board: Board) -> [Move] {
        let legal = movesIgnoringForcedCapture(for: color, on: board)
        let forced = legal.filter { isForcedCapture($0, on: board) }
        return forced.isEmpty ? legal : forced
    }

    /// 이 수가 "강제 캡처" 대상인가
    static func isForcedCapture(_ move: Move, on board: Board) -> Bool {
        guard board[move.to] != nil else { return false }
        if board[move.from]?.kind == .queen {
            return SquareUtil.chebyshev(move.from, move.to) <= 2
        }
        return true
    }

    /// 현재 색의 합법수 중 강제 캡처가 존재하는가 (UI 안내용)
    static func hasForcedCapture(for color: PieceColor, on board: Board) -> Bool {
        movesIgnoringForcedCapture(for: color, on: board).contains { isForcedCapture($0, on: board) }
    }

    private static func appendPseudoMoves(for piece: Piece, at sq: Square, on board: Board, into moves: inout [Move]) {
        let f = SquareUtil.file(sq)
        let r = SquareUtil.rank(sq)

        func addIfPossible(file: Int, rank: Int) {
            guard SquareUtil.isValid(file: file, rank: rank) else { return }
            let to = SquareUtil.make(file: file, rank: rank)
            if board[to]?.color != piece.color {
                moves.append(Move(from: sq, to: to))
            }
        }

        func slide(_ dirs: [(Int, Int)]) {
            for (df, dr) in dirs {
                var nf = f + df, nr = r + dr
                while SquareUtil.isValid(file: nf, rank: nr) {
                    let to = SquareUtil.make(file: nf, rank: nr)
                    if let occupant = board[to] {
                        if occupant.color != piece.color { moves.append(Move(from: sq, to: to)) }
                        break
                    }
                    moves.append(Move(from: sq, to: to))
                    nf += df
                    nr += dr
                }
            }
        }

        switch piece.kind {
        case .pawn:
            let dir = piece.color == .white ? 1 : -1
            let startRank = piece.color == .white ? 1 : 6
            let promoRank = piece.color == .white ? 7 : 0

            func addPawnMove(to: Square) {
                if SquareUtil.rank(to) == promoRank {
                    for promo in [PieceKind.queen, .rook, .bishop, .knight] {
                        moves.append(Move(from: sq, to: to, promotion: promo))
                    }
                } else {
                    moves.append(Move(from: sq, to: to))
                }
            }

            // 전진
            if SquareUtil.isValid(file: f, rank: r + dir) {
                let one = SquareUtil.make(file: f, rank: r + dir)
                if board[one] == nil {
                    addPawnMove(to: one)
                    if r == startRank {
                        let two = SquareUtil.make(file: f, rank: r + dir * 2)
                        if board[two] == nil { moves.append(Move(from: sq, to: two)) }
                    }
                }
            }
            // 대각 캡처
            for df in [-1, 1] {
                guard SquareUtil.isValid(file: f + df, rank: r + dir) else { continue }
                let to = SquareUtil.make(file: f + df, rank: r + dir)
                if let occupant = board[to], occupant.color != piece.color {
                    addPawnMove(to: to)
                }
            }
        case .knight:
            for (df, dr) in knightSteps { addIfPossible(file: f + df, rank: r + dr) }
        case .king:
            for (df, dr) in kingSteps { addIfPossible(file: f + df, rank: r + dr) }
        case .rook:
            slide(rookDirs)
        case .bishop:
            slide(bishopDirs)
        case .queen:
            slide(rookDirs + bishopDirs)
        }
    }
}
