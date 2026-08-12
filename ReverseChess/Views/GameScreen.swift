import SwiftUI

enum GameMode: Hashable {
    case vsBot(BotLevel)
    case twoPlayer

    var title: String {
        switch self {
        case .vsBot(let level): return "컴퓨터 대전 · \(level.korean)"
        case .twoPlayer: return "함께 하기"
        }
    }
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published var game = Game()
    @Published var selected: Square?
    @Published var pendingPromotion: (from: Square, to: Square)?
    @Published var isBotThinking = false

    let mode: GameMode
    /// vsBot 모드에서 사람이 조종하는 색 (흑 선공이므로 사람이 흑)
    let humanColor: PieceColor = .black

    init(mode: GameMode) {
        self.mode = mode
    }

    var botLevel: BotLevel? {
        if case .vsBot(let level) = mode { return level }
        return nil
    }

    var isHumanTurn: Bool {
        guard !game.isFinished else { return false }
        guard botLevel != nil else { return true }
        return game.sideToMove == humanColor
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

    private func perform(_ move: Move) {
        let isCapture = game.board[move.to] != nil
        guard game.play(move) else { return }
        isCapture ? Haptics.capture() : Haptics.move()

        if game.isFinished {
            announceResult()
        } else {
            scheduleBotIfNeeded()
        }
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
        if botLevel == nil || winner == humanColor {
            Haptics.success()
        } else {
            Haptics.failure()
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

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 14) {
                playerPanel(for: .white)

                BoardView(
                    board: model.game.board,
                    lastMove: model.game.lastMove,
                    selected: model.selected,
                    targets: model.targets,
                    forcedTargets: model.forcedTargets,
                    onTap: model.handleTap
                )
                .padding(.horizontal, 12)

                playerPanel(for: .black)
                statusBanner
                Spacer(minLength: 0)
            }
            .padding(.top, 8)

            if model.game.isFinished {
                resultOverlay
            }
        }
        .navigationTitle(model.mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "프로모션 — 어떤 기물로 바꿀까요?",
            isPresented: Binding(
                get: { model.pendingPromotion != nil },
                set: { if !$0 { model.pendingPromotion = nil } }
            ),
            titleVisibility: .visible
        ) {
            ForEach([PieceKind.queen, .rook, .bishop, .knight], id: \.self) { kind in
                Button(kind.korean) { model.promote(to: kind) }
            }
        }
    }

    // MARK: - 구성 요소

    private func playerPanel(for color: PieceColor) -> some View {
        let isTurn = !model.game.isFinished && model.game.sideToMove == color
        let name: String = {
            switch model.mode {
            case .vsBot: return color == model.humanColor ? "나 (흑)" : "컴퓨터 (백)"
            case .twoPlayer: return color == .black ? "흑 플레이어" : "백 플레이어"
            }
        }()

        return HStack(spacing: 10) {
            Circle()
                .fill(color == .white ? Theme.pieceWhite : Theme.pieceBlack)
                .frame(width: 14, height: 14)
                .overlay(Circle().strokeBorder(.black.opacity(0.2)))
            Text(name)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
            if isTurn {
                if model.isBotThinking {
                    ProgressView().scaleEffect(0.7)
                } else {
                    Text("차례")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Theme.accentSoft))
                        .foregroundStyle(Theme.accent)
                }
            }
            Spacer()

            // 리버스 진행도: 기물을 잃을수록 승리에 가까워진다
            VStack(alignment: .trailing, spacing: 2) {
                Text("남은 기물 \(model.game.board.nonKingCount(of: color))")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                ProgressView(value: model.reverseProgress(for: color))
                    .tint(Theme.accent)
                    .frame(width: 90)
            }
        }
        .padding(.horizontal, 20)
    }

    private var statusBanner: some View {
        Group {
            if model.game.isInCheck && !model.game.isFinished {
                bannerLabel("체크! 반드시 피해야 해요", icon: "exclamationmark.triangle.fill", color: Theme.coral)
            } else if model.game.hasForcedCapture && !model.game.isFinished {
                bannerLabel("강제 캡처 — 잡을 수 있으면 잡아야 해요", icon: "target", color: Theme.coral)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.game.moveCount)
    }

    private func bannerLabel(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.system(.footnote, design: .rounded, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill(color.opacity(0.12)))
    }

    private var resultOverlay: some View {
        VStack(spacing: 18) {
            Text(resultEmoji)
                .font(.system(size: 56))
            Text(resultTitle)
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text(resultDetail)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button {
                    model.restart()
                } label: {
                    Label("한 판 더", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)

                Button {
                    dismiss()
                } label: {
                    Label("홈으로", systemImage: "house")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 8)
        }
        .padding(28)
        .frame(maxWidth: 320)
        .cardStyle()
        .padding(24)
        .transition(.scale.combined(with: .opacity))
    }

    private var resultEmoji: String {
        switch model.game.result {
        case .win(let winner, _):
            if model.botLevel != nil {
                return winner == model.humanColor ? "🎉" : "😢"
            }
            return "🏆"
        case .draw: return "🤝"
        case nil: return ""
        }
    }

    private var resultTitle: String {
        switch model.game.result {
        case .win(let winner, _):
            if model.botLevel != nil {
                return winner == model.humanColor ? "승리!" : "패배..."
            }
            return "\(winner.korean) 승리!"
        case .draw: return "무승부"
        case nil: return ""
        }
    }

    private var resultDetail: String {
        switch model.game.result {
        case .win(_, let reason):
            switch reason {
            case .onlyKingLeft: return "킹만 남기고 모든 기물을 버리는 데 성공했어요."
            case .checkmated: return "체크메이트에 몰린 쪽이 승리하는 게임! 훌륭해요."
            case .loneIsland: return "외딴 섬 — 킹 말고는 움직일 기물이 없어서 승리!"
            }
        case .draw(let reason): return reason.korean + "으로 무승부입니다."
        case nil: return ""
        }
    }
}
