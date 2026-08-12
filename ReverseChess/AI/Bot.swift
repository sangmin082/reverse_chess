import Foundation

enum BotLevel: String, CaseIterable, Identifiable {
    case easy, hard

    var id: String { rawValue }
    var korean: String { self == .easy ? "쉬움" : "어려움" }
    var depth: Int { self == .easy ? 2 : 4 }
}

/// 리버스 체스 AI — 네가맥스 + 알파베타.
/// 평가: 내 기물이 적을수록 좋다 (기물을 버리는 것이 승리 조건이므로).
enum Bot {

    static func bestMove(in game: Game, level: BotLevel) -> Move? {
        let moves = game.legalMoves()
        guard !moves.isEmpty else { return nil }
        if moves.count == 1 { return moves[0] }

        var scored: [(Move, Int)] = []
        for move in moves {
            var next = game
            next.play(move)
            let score = -negamax(
                game: next, depth: level.depth - 1,
                alpha: Int.min / 2, beta: Int.max / 2,
                perspective: next.sideToMove
            )
            scored.append((move, score))
        }
        scored.shuffle()
        scored.sort { $0.1 > $1.1 }

        // 쉬움: 상위 후보 중 무작위 선택으로 실수 유도
        if level == .easy, scored.count > 1, Int.random(in: 0..<100) < 35 {
            let pool = Array(scored.prefix(min(3, scored.count)))
            return pool.randomElement()?.0
        }
        return scored.first?.0
    }

    private static func negamax(game: Game, depth: Int, alpha: Int, beta: Int, perspective: PieceColor) -> Int {
        if let result = game.result {
            switch result {
            case .win(let winner, _):
                return winner == perspective ? 100_000 - (100 - depth) : -100_000 + (100 - depth)
            case .draw:
                return 0
            }
        }
        if depth <= 0 {
            return evaluate(board: game.board, for: perspective)
        }

        var alpha = alpha
        var best = Int.min / 2
        for move in game.legalMoves() {
            var next = game
            next.play(move)
            let score = -negamax(
                game: next, depth: depth - 1,
                alpha: -beta, beta: -alpha,
                perspective: next.sideToMove
            )
            best = max(best, score)
            alpha = max(alpha, score)
            if alpha >= beta { break }
        }
        return best
    }

    /// 관점 색 기준 점수: 상대 기물이 많고 내 기물이 적을수록 높다.
    private static func evaluate(board: Board, for color: PieceColor) -> Int {
        let mine = board.material(of: color)
        let theirs = board.material(of: color.opposite)
        var score = (theirs - mine) * 100

        // 내 기물 수 자체도 줄이는 방향 선호 (킹 제외)
        score += (board.nonKingCount(of: color.opposite) - board.nonKingCount(of: color)) * 20

        // 내 기동력이 킹에 가까워질수록(외딴 섬 근접) 보너스는 생략 — 단순 유지
        return score
    }
}
