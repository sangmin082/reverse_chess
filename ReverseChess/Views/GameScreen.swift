import SwiftUI

enum GameMode: Hashable {
    case vsBot(BotLevel)
    case twoPlayer
    /// 온라인 대전 — 연관값은 내가 둘 색 (서버가 배정)
    case online(PieceColor)

    var title: String {
        switch self {
        case .vsBot(let level): return String(localized: "컴퓨터 대전 · \(level.localizedName)")
        case .twoPlayer: return String(localized: "함께 하기")
        case .online: return String(localized: "온라인 대전")
        }
    }
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published var game = Game()
    @Published var selected: Square?
    @Published var pendingPromotion: (from: Square, to: Square)?
    @Published var isBotThinking = false
    @Published var opponentLeft = false

    let mode: GameMode
    /// 사람이 조종하는 색 — vsBot은 흑(선공), 온라인은 서버 배정
    let humanColor: PieceColor
    private let client: RoomClient?

    init(mode: GameMode, client: RoomClient? = nil) {
        self.mode = mode
        self.client = client
        if case .online(let color) = mode {
            self.humanColor = color
        } else {
            self.humanColor = .black
        }
        client?.onRemoteMove = { [weak self] move in
            self?.applyRemote(move)
        }
        client?.onOpponentLeft = { [weak self] in
            self?.opponentLeft = true
        }
    }

    var botLevel: BotLevel? {
        if case .vsBot(let level) = mode { return level }
        return nil
    }

    var isOnline: Bool {
        if case .online = mode { return true }
        return false
    }

    var isHumanTurn: Bool {
        guard !game.isFinished, !opponentLeft else { return false }
        switch mode {
        case .twoPlayer: return true
        case .vsBot, .online: return game.sideToMove == humanColor
        }
    }

    var targets: Set<Square> {
        guard let sel = selected else { return [] }
        return Set(game.legalMoves(from: sel).map(\.to))
    }

    var forcedTargets: Set<Square> {
        guard let sel = selected else { return [] }
        return Set(
            game.legalMoves(from: sel)
                .filter { Rules.isForcedCapture($0, on: game.board) }
                .map(\.to)
        )
    }

    /// "기물을 잃을수록 승리에 가까워지는" 리버스 진행도 (0.0 = 시작, 1.0 = 왕만 남음)
    func reverseProgress(for color: PieceColor) -> Double {
        Double(15 - game.board.nonKingCount(of: color)) / 15.0
    }

    func handleTap(_ sq: Square) {
        guard isHumanTurn else { return }

        if let sel = selected {
            let candidates = game.legalMoves(from: sel).filter { $0.to == sq }
            if !candidates.isEmpty {
                if candidates.count > 1 {
                    // 프로모션: 선택지를 물어본다
                    pendingPromotion = (from: sel, to: sq)
                } else {
                    perform(candidates[0])
                }
                selected = nil
                return
            }
        }

        if let piece = game.board[sq], piece.color == game.sideToMove,
           !game.legalMoves(from: sq).isEmpty {
            selected = (selected == sq) ? nil : sq
            Haptics.tap()
        } else {
            selected = nil
        }
    }

    func promote(to kind: PieceKind) {
        guard let pending = pendingPromotion else { return }
        pendingPromotion = nil
        perform(Move(from: pending.from, to: pending.to, promotion: kind))
    }

    private func perform(_ move: Move, fromRemote: Bool = false) {
        let isCapture = game.board[move.to] != nil
        guard game.play(move) else { return }
        isCapture ? Haptics.capture() : Haptics.move()

        if isOnline && !fromRemote {
            client?.send(move: move)
        }

        if game.isFinished {
            announceResult()
        } else {
            scheduleBotIfNeeded()
        }
    }

    /// 온라인 상대의 무브 적용
    func applyRemote(_ move: Move) {
        guard isOnline, game.sideToMove != humanColor else { return }
        perform(move, fromRemote: true)
    }

    func scheduleBotIfNeeded() {
        guard let level = botLevel, !game.isFinished, game.sideToMove != humanColor else { return }
        isBotThinking = true
        let snapshot = game
        Task.detached(priority: .userInitiated) {
            let move = Bot.bestMove(in: snapshot, level: level)
            // 최소한의 "생각하는" 연출
            try? await Task.sleep(nanoseconds: 450_000_000)
            await MainActor.run { [weak self] in
                guard let self, !self.game.isFinished else { return }
                self.isBotThinking = false
                if let move { self.perform(move) }
            }
        }
    }

    private func announceResult() {
        guard case .win(let winner, _)? = game.result else { return }
        if case .twoPlayer = mode {
            Haptics.success()
        } else {
            winner == humanColor ? Haptics.success() : Haptics.failure()
        }
    }

    func restart() {
        game = Game()
        selected = nil
        pendingPromotion = nil
        isBotThinking = false
    }
}

struct GameScreen: View {
    @StateObject private var model: GameViewModel
    @Environment(\.dismiss) private var dismiss

    init(mode: GameMode) {
        _model = StateObject(wrappedValue: GameViewModel(mode: mode))
    }

    /// 외부에서 구성한 모델로 표시 (온라인 대전)
    init(model: GameViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            VStack(spacing: 12) {
                playerPanel(for: .white)

                BoardView(
                    board: model.game.board,
                    lastMove: model.game.lastMove,
                    selected: model.selected,
                    targets: model.targets,
                    forcedTargets: model.forcedTargets,
                    onTap: model.handleTap
                )
                .padding(.horizontal, 14)

                playerPanel(for: .black)
                statusBanner
                Spacer(minLength: 0)
            }
            .padding(.top, 8)

            if model.game.isFinished {
                Theme.ink.opacity(0.25).ignoresSafeArea()
                resultOverlay
            } else if model.opponentLeft {
                Theme.ink.opacity(0.25).ignoresSafeArea()
                opponentLeftOverlay
            }
        }
        .navigationTitle(model.mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.paper, for: .navigationBar)
        .confirmationDialog(
            "프로모션 — 어떤 기물로 바꿀까요?",
            isPresented: Binding(
                get: { model.pendingPromotion != nil },
                set: { if !$0 { model.pendingPromotion = nil } }
            ),
            titleVisibility: .visible
        ) {
            ForEach([PieceKind.queen, .rook, .bishop, .knight], id: \.self) { kind in
                Button(kind.localizedName) { model.promote(to: kind) }
            }
        }
    }

    // MARK: - 구성 요소

    private func playerPanel(for color: PieceColor) -> some View {
        let isTurn = !model.game.isFinished && model.game.sideToMove == color
        let name: String = {
            switch model.mode {
            case .vsBot: return color == model.humanColor
                ? String(localized: "나 · 흑") : String(localized: "컴퓨터 · 백")
            case .twoPlayer: return color.localizedName
            case .online: return color == model.humanColor
                ? String(localized: "나 · \(color.localizedName)")
                : String(localized: "상대 · \(color.localizedName)")
            }
        }()

        return HStack(spacing: 10) {
            Text(color == .white ? "♚\u{FE0E}" : "♚\u{FE0E}")
                .font(.system(size: 17))
                .foregroundStyle(color == .white ? Theme.pieceWhite : Theme.ink)
                .shadow(color: color == .white ? Theme.ink.opacity(0.6) : .clear, radius: 0.6, y: 0.6)

            Text(name)
                .font(.system(.subheadline, design: .serif, weight: .bold))
                .foregroundStyle(Theme.ink)

            if isTurn {
                if model.isBotThinking {
                    Text("생각 중…")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    Circle().fill(Theme.accent).frame(width: 7, height: 7)
                }
            }
            Spacer()

            // 리버스 진행도: 기물을 잃을수록 승리에 가까워진다
            VStack(alignment: .trailing, spacing: 3) {
                Text("남은 기물 \(model.game.board.nonKingCount(of: color))")
                    .font(.caption2)
                    .foregroundStyle(Theme.inkSoft)
                ProgressView(value: model.reverseProgress(for: color))
                    .tint(Theme.accent)
                    .frame(width: 84)
            }
        }
        .padding(.horizontal, 22)
    }

    private var statusBanner: some View {
        Group {
            if model.game.isInCheck && !model.game.isFinished {
                bannerLabel("체크 — 반드시 피해야 합니다")
            } else if model.game.hasForcedCapture && !model.game.isFinished {
                bannerLabel("강제 캡처 — 잡을 수 있으면 잡아야 합니다")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.game.moveCount)
    }

    private func bannerLabel(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(.footnote, weight: .semibold))
            .foregroundStyle(Theme.accent)
            .padding(.top, 2)
    }

    private var resultOverlay: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(resultTitle)
                .font(.system(size: 34, weight: .black, design: .serif))
                .foregroundStyle(Theme.ink)
            Rectangle().fill(Theme.accent).frame(width: 44, height: 3)
            Text(resultDetail)
                .font(.system(.subheadline))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                if !model.isOnline {
                    Button("한 판 더") { model.restart() }
                        .buttonStyle(InkButtonStyle(filled: true))
                }
                Button("홈으로") { dismiss() }
                    .buttonStyle(InkButtonStyle(filled: model.isOnline))
            }
            .padding(.top, 8)
        }
        .padding(26)
        .frame(maxWidth: 330, alignment: .leading)
        .panelStyle()
        .padding(24)
        .transition(.scale.combined(with: .opacity))
    }

    private var opponentLeftOverlay: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("상대가 나갔습니다")
                .font(.system(size: 26, weight: .black, design: .serif))
                .foregroundStyle(Theme.ink)
            Rectangle().fill(Theme.accent).frame(width: 44, height: 3)
            Text("연결이 끊어져 대국을 계속할 수 없습니다.")
                .font(.system(.subheadline))
                .foregroundStyle(Theme.inkSoft)
            Button("홈으로") { dismiss() }
                .buttonStyle(InkButtonStyle(filled: true))
                .padding(.top, 8)
        }
        .padding(26)
        .frame(maxWidth: 330, alignment: .leading)
        .panelStyle()
        .padding(24)
        .transition(.scale.combined(with: .opacity))
    }

    private var resultTitle: String {
        switch model.game.result {
        case .win(let winner, _):
            if model.botLevel != nil || model.isOnline {
                return winner == model.humanColor
                    ? String(localized: "승리") : String(localized: "패배")
            }
            return String(localized: "\(winner.localizedName)의 승리")
        case .draw: return String(localized: "무승부")
        case nil: return ""
        }
    }

    private var resultDetail: String {
        switch model.game.result {
        case .win(_, let reason):
            switch reason {
            case .onlyKingLeft:
                return String(localized: "킹만 남기고 모든 기물을 버려서 승리했습니다.")
            case .checkmated:
                return String(localized: "체크메이트를 당하면 승리하는 게임 — 그렇게 끝났습니다.")
            case .loneIsland:
                return String(localized: "외딴 섬 — 킹 말고는 움직일 기물이 없어서 승리했습니다.")
            }
        case .draw(let reason):
            switch reason {
            case .stalemate:
                return String(localized: "스테일메이트로 무승부입니다.")
            case .threefoldRepetition:
                return String(localized: "같은 위치가 세 번 반복되어 무승부입니다.")
            case .fiftyMoveRule:
                return String(localized: "50수 동안 캡처와 폰 이동이 없어 무승부입니다.")
            }
        case nil: return ""
        }
    }
}
