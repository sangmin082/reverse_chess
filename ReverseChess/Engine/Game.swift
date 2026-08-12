import Foundation

/// 게임 종료 사유
enum GameResult: Equatable {
    case win(PieceColor, WinReason)
    case draw(DrawReason)

    enum WinReason: Equatable {
        /// 킹을 제외한 모든 기물을 잃음
        case onlyKingLeft
        /// 체크메이트를 "당한" 쪽이 승리
        case checkmated
        /// 체크가 아닌데 움직일 수 있는 기물이 킹뿐 (다른 기물은 남아 있음)
        case loneIsland

        var korean: String {
            switch self {
            case .onlyKingLeft: return "왕만 남음"
            case .checkmated: return "체크메이트"
            case .loneIsland: return "외딴 섬"
            }
        }
    }

    enum DrawReason: Equatable {
        case stalemate
        case threefoldRepetition
        case fiftyMoveRule

        var korean: String {
            switch self {
            case .stalemate: return "스테일메이트"
            case .threefoldRepetition: return "3회 동형"
            case .fiftyMoveRule: return "50수 규칙"
            }
        }
    }
}

/// 한 판의 진행 상태 (값 타입)
struct Game {
    private(set) var board: Board
    private(set) var sideToMove: PieceColor
    private(set) var result: GameResult?
    private(set) var lastMove: Move?
    private(set) var moveCount: Int = 0

    /// 50수 규칙: 캡처/폰 이동 없이 지나간 반수(half-move) 수
    private(set) var quietHalfMoves: Int = 0
    private var positionCounts: [String: Int] = [:]

    /// 흑이 선공
    init(board: Board = .initial(), sideToMove: PieceColor = .black) {
        self.board = board
        self.sideToMove = sideToMove
        self.positionCounts[board.positionKey(sideToMove: sideToMove)] = 1
        self.result = Self.evaluateResult(
            board: board, sideToMove: sideToMove,
            quietHalfMoves: 0, positionCounts: positionCounts
        )
    }

    var isFinished: Bool { result != nil }

    func legalMoves() -> [Move] {
        isFinished ? [] : Rules.legalMoves(for: sideToMove, on: board)
    }

    func legalMoves(from sq: Square) -> [Move] {
        legalMoves().filter { $0.from == sq }
    }

    var isInCheck: Bool { Rules.isInCheck(sideToMove, on: board) }
    var hasForcedCapture: Bool { Rules.hasForcedCapture(for: sideToMove, on: board) }

    @discardableResult
    mutating func play(_ move: Move) -> Bool {
        guard !isFinished, legalMoves().contains(move) else { return false }

        let isCapture = board[move.to] != nil
        let isPawnMove = board[move.from]?.kind == .pawn
        board.apply(move)
        lastMove = move
        moveCount += 1
        quietHalfMoves = (isCapture || isPawnMove) ? 0 : quietHalfMoves + 1
        sideToMove = sideToMove.opposite

        let key = board.positionKey(sideToMove: sideToMove)
        positionCounts[key, default: 0] += 1

        result = Self.evaluateResult(
            board: board, sideToMove: sideToMove,
            quietHalfMoves: quietHalfMoves, positionCounts: positionCounts
        )
        return true
    }

    /// 종료 판정. `sideToMove`는 지금 둘 차례인 쪽.
    static func evaluateResult(
        board: Board, sideToMove: PieceColor,
        quietHalfMoves: Int, positionCounts: [String: Int]
    ) -> GameResult? {
        // 1. 왕만 남음 → 그 플레이어 승리 (둘 다는 동시에 될 수 없음: 이전 판정에서 이미 끝났을 것)
        for color in PieceColor.allCases where board.nonKingCount(of: color) == 0 {
            return .win(color, .onlyKingLeft)
        }

        let moves = Rules.legalMoves(for: sideToMove, on: board)
        let inCheck = Rules.isInCheck(sideToMove, on: board)

        // 2. 둘 수 있는 수가 없음: 체크메이트면 "당한 쪽" 승리, 아니면 스테일메이트 무승부
        if moves.isEmpty {
            return inCheck ? .win(sideToMove, .checkmated) : .draw(.stalemate)
        }

        // 3. 외딴 섬: 체크가 아니고, 움직일 수 있는 기물이 킹뿐이면 그 플레이어 승리
        if !inCheck && moves.allSatisfy({ board[$0.from]?.kind == .king }) {
            return .win(sideToMove, .loneIsland)
        }

        // 4. 무승부 규칙
        if positionCounts[board.positionKey(sideToMove: sideToMove)] ?? 0 >= 3 {
            return .draw(.threefoldRepetition)
        }
        if quietHalfMoves >= 100 {
            return .draw(.fiftyMoveRule)
        }
        return nil
    }
}
