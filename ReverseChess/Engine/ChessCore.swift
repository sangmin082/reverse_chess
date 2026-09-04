import Foundation

// MARK: - 기본 타입

enum PieceColor: String, Codable, Hashable, CaseIterable {
    case white, black

    var opposite: PieceColor { self == .white ? .black : .white }
    var localizedName: String {
        self == .white ? String(localized: "백") : String(localized: "흑")
    }
}

enum PieceKind: String, Codable, Hashable, CaseIterable {
    case pawn, knight, bishop, rook, queen, king

    var value: Int {
        switch self {
        case .pawn: return 1
        case .knight: return 3
        case .bishop: return 3
        case .rook: return 5
        case .queen: return 9
        case .king: return 0
        }
    }

    var localizedName: String {
        switch self {
        case .pawn: return String(localized: "폰")
        case .knight: return String(localized: "나이트")
        case .bishop: return String(localized: "비숍")
        case .rook: return String(localized: "룩")
        case .queen: return String(localized: "퀸")
        case .king: return String(localized: "킹")
        }
    }
}

struct Piece: Hashable, Codable {
    let color: PieceColor
    let kind: PieceKind

    /// 두 색 모두 "채워진" 글리프를 쓰고 색으로만 구분한다.
    /// U+FE0E(텍스트 변형 선택자)를 붙여 iOS가 ♟ 등을 이모지로 렌더링하는 것을 막는다.
    var glyph: String {
        let base: String
        switch kind {
        case .king: base = "♚"
        case .queen: base = "♛"
        case .rook: base = "♜"
        case .bishop: base = "♝"
        case .knight: base = "♞"
        case .pawn: base = "♟"
        }
        return base + "\u{FE0E}"
    }
}

/// 0...63. file = sq % 8 (a=0), rank = sq / 8 (rank1 = 0, 백 진영이 아래)
typealias Square = Int

enum SquareUtil {
    static func make(file: Int, rank: Int) -> Square { rank * 8 + file }
    static func file(_ sq: Square) -> Int { sq % 8 }
    static func rank(_ sq: Square) -> Int { sq / 8 }
    static func isValid(file: Int, rank: Int) -> Bool {
        file >= 0 && file < 8 && rank >= 0 && rank < 8
    }
    static func chebyshev(_ a: Square, _ b: Square) -> Int {
        max(abs(file(a) - file(b)), abs(rank(a) - rank(b)))
    }
    /// "a1" 형태 표기 (디버깅용)
    static func name(_ sq: Square) -> String {
        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        return "\(files[file(sq)])\(rank(sq) + 1)"
    }
}

struct Move: Hashable, Codable {
    let from: Square
    let to: Square
    var promotion: PieceKind? = nil
}

// MARK: - 보드

struct Board: Hashable {
    /// 64칸. nil = 빈 칸
    private(set) var cells: [Piece?]

    init(cells: [Piece?]) {
        precondition(cells.count == 64)
        self.cells = cells
    }

    /// 리버스 체스 초기 배치.
    /// 백 1랭크: R N B Q K B N R / 흑 8랭크: R N B K Q B N R (킹·퀸 위치가 백과 거울 대칭)
    static func initial() -> Board {
        var cells = [Piece?](repeating: nil, count: 64)
        let whiteBack: [PieceKind] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        let blackBack: [PieceKind] = [.rook, .knight, .bishop, .king, .queen, .bishop, .knight, .rook]
        for f in 0..<8 {
            cells[SquareUtil.make(file: f, rank: 0)] = Piece(color: .white, kind: whiteBack[f])
            cells[SquareUtil.make(file: f, rank: 1)] = Piece(color: .white, kind: .pawn)
            cells[SquareUtil.make(file: f, rank: 6)] = Piece(color: .black, kind: .pawn)
            cells[SquareUtil.make(file: f, rank: 7)] = Piece(color: .black, kind: blackBack[f])
        }
        return Board(cells: cells)
    }

    /// 튜토리얼 등 임의 배치를 위한 생성자. ("a1", 기물) 목록
    static func custom(_ placements: [(String, Piece)]) -> Board {
        var cells = [Piece?](repeating: nil, count: 64)
        for (name, piece) in placements {
            guard name.count == 2,
                  let fileChar = name.first, let rankChar = name.last,
                  let fileIdx = "abcdefgh".firstIndex(of: fileChar),
                  let rank = rankChar.wholeNumberValue else { continue }
            let f = "abcdefgh".distance(from: "abcdefgh".startIndex, to: fileIdx)
            cells[SquareUtil.make(file: f, rank: rank - 1)] = piece
        }
        return Board(cells: cells)
    }

    subscript(_ sq: Square) -> Piece? {
        get { cells[sq] }
        set { cells[sq] = newValue }
    }

    func pieces(of color: PieceColor) -> [(Square, Piece)] {
        var result: [(Square, Piece)] = []
        for sq in 0..<64 {
            if let p = cells[sq], p.color == color { result.append((sq, p)) }
        }
        return result
    }

    func kingSquare(of color: PieceColor) -> Square? {
        for sq in 0..<64 {
            if let p = cells[sq], p.color == color, p.kind == .king { return sq }
        }
        return nil
    }

    func material(of color: PieceColor) -> Int {
        pieces(of: color).reduce(0) { $0 + $1.1.kind.value }
    }

    /// 킹을 제외한 기물 수
    func nonKingCount(of color: PieceColor) -> Int {
        pieces(of: color).filter { $0.1.kind != .king }.count
    }

    mutating func apply(_ move: Move) {
        var piece = cells[move.from]
        if let promo = move.promotion, piece?.kind == .pawn {
            piece = Piece(color: piece!.color, kind: promo)
        }
        cells[move.to] = piece
        cells[move.from] = nil
    }

    func applying(_ move: Move) -> Board {
        var b = self
        b.apply(move)
        return b
    }

    /// 3회 동형 판정용 위치 키
    func positionKey(sideToMove: PieceColor) -> String {
        var key = sideToMove == .white ? "w:" : "b:"
        for sq in 0..<64 {
            if let p = cells[sq] {
                let c = p.color == .white ? "W" : "B"
                key += "\(sq)\(c)\(p.kind.rawValue.prefix(2))"
            }
        }
        return key
    }
}
