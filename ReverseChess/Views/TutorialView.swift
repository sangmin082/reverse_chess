import SwiftUI

// MARK: - 레슨 정의 (미션 기반: 직접 정답 수를 찾아야 통과)

struct TutorialLesson: Identifiable {
    let id: Int
    let title: String
    let story: String
    let goal: String
    let hint: String
    let board: Board
    /// 성공 판정: 플레이어가 둔 수를 받아 통과 여부 반환
    let isSuccess: (Move) -> Bool
    /// 성공 후 백의 강제 응수를 자동 재생할지 (승리 체험 미션용)
    var playsWhiteReply: Bool = false

    static let all: [TutorialLesson] = [
        TutorialLesson(
            id: 0,
            title: "흑이 먼저 시작해요",
            story: "리버스 체스의 목표는 정반대예요. 기물을 지키는 게 아니라, 킹만 남기고 전부 잃어야 이깁니다. 그리고 첫 수는 백이 아니라 흑의 몫이에요.",
            goal: "아무 기물이나 움직여 첫 수를 두세요.",
            hint: "기물을 탭하면 갈 수 있는 칸이 표시돼요.",
            board: .initial(),
            isSuccess: { _ in true }
        ),
        TutorialLesson(
            id: 1,
            title: "잡을 수 있으면 잡아야 해요",
            story: "잡을 수 있는 기물이 있다면 반드시 그중 하나를 잡아야 해요. 기물을 잃는 게 목표인 게임이라, 이 규칙이 승부의 핵심이 됩니다.",
            goal: "지금 둘 수 있는 수는 단 하나뿐이에요. 찾아보세요.",
            hint: "룩은 움직일 수 없어요. 폰으로 잡을 수 있는 것을 찾아보세요.",
            board: .custom([
                ("h8", Piece(color: .black, kind: .king)),
                ("a8", Piece(color: .black, kind: .rook)),
                ("d5", Piece(color: .black, kind: .pawn)),
                ("h1", Piece(color: .white, kind: .king)),
                ("c4", Piece(color: .white, kind: .pawn)),
            ]),
            isSuccess: { move in
                move.from == SquareUtil.make(file: 3, rank: 4) && move.to == SquareUtil.make(file: 2, rank: 3)
            }
        ),
        TutorialLesson(
            id: 2,
            title: "퀸은 2칸까지만 강제예요",
            story: "예외가 하나 있어요. 퀸의 캡처는 가로·세로·대각선 2칸 이내일 때만 강제입니다. 멀리 있는 기물은 퀸으로 '잡을 수 있어 보여도' 강제 대상이 아니에요.",
            goal: "퀸이 아닌, 반드시 잡아야 하는 기물로 캡처하세요.",
            hint: "퀸과 룩의 거리를 세어보세요. 폰의 대각선을 보세요.",
            board: .custom([
                ("h8", Piece(color: .black, kind: .king)),
                ("d8", Piece(color: .black, kind: .queen)),
                ("e4", Piece(color: .black, kind: .pawn)),
                ("h1", Piece(color: .white, kind: .king)),
                ("d3", Piece(color: .white, kind: .pawn)),
                ("d1", Piece(color: .white, kind: .rook)),
            ]),
            isSuccess: { move in
                move.from == SquareUtil.make(file: 4, rank: 3) && move.to == SquareUtil.make(file: 3, rank: 2)
            }
        ),
        TutorialLesson(
            id: 3,
            title: "체크가 먼저예요",
            story: "체크 규칙은 기본 체스 그대로예요. 체크를 당하면 반드시 피해야 하고, 강제 캡처보다 체크 피하기가 우선입니다. 스스로 체크에 들어가는 수도 둘 수 없어요.",
            goal: "체크에서 벗어나세요.",
            hint: "룩의 시선에서 킹을 벗어나게 하세요.",
            board: .custom([
                ("e8", Piece(color: .black, kind: .king)),
                ("a5", Piece(color: .black, kind: .pawn)),
                ("e1", Piece(color: .white, kind: .rook)),
                ("h1", Piece(color: .white, kind: .king)),
            ]),
            isSuccess: { _ in true }
        ),
        TutorialLesson(
            id: 4,
            title: "폰은 변신할 수 있어요",
            story: "폰이 끝까지 전진하면 퀸·룩·비숍·나이트로 변신해요. 캐슬링과 앙파상은 없지만, 프로모션은 그대로 있습니다. 참고로 기물이 커지는 게 꼭 좋은 것만은 아니에요!",
            goal: "폰을 끝까지 전진시켜 변신시키세요.",
            hint: "폰을 1랭크까지 밀어보세요.",
            board: .custom([
                ("h8", Piece(color: .black, kind: .king)),
                ("b2", Piece(color: .black, kind: .pawn)),
                ("h4", Piece(color: .white, kind: .king)),
                ("h2", Piece(color: .white, kind: .pawn)),
            ]),
            isSuccess: { move in move.promotion != nil }
        ),
        TutorialLesson(
            id: 5,
            title: "버리는 자가 이긴다",
            story: "이제 실전 감각이에요. 상대는 잡을 수 있으면 잡아야만 하죠. 그러니 내 기물을 일부러 상대의 공격 범위에 놓으면, 상대는 어쩔 수 없이 잡아줍니다. 마지막 기물을 버려서 직접 승리해보세요!",
            goal: "룩을 백 폰이 잡을 수밖에 없는 곳에 놓으세요.",
            hint: "폰은 대각선으로만 잡아요. 폰의 대각선 앞에 룩을 놓아보세요.",
            board: .custom([
                ("a8", Piece(color: .black, kind: .king)),
                ("h5", Piece(color: .black, kind: .rook)),
                ("a1", Piece(color: .white, kind: .king)),
                ("g3", Piece(color: .white, kind: .pawn)),
            ]),
            isSuccess: { move in
                move.from == SquareUtil.make(file: 7, rank: 4) && move.to == SquareUtil.make(file: 7, rank: 3)
            },
            playsWhiteReply: true
        ),
    ]
}

// MARK: - 튜토리얼 화면

@MainActor
final class TutorialViewModel: ObservableObject {
    @Published var lessonIndex = 0
    @Published var game: Game
    @Published var selected: Square?
    @Published var phase: Phase = .intro
    @Published var showHint = false

    enum Phase {
        case intro        // 레슨 소개 카드
        case playing      // 미션 수행 중
        case wrong        // 오답 → 다시
        case success      // 통과
        case finished     // 전체 완료
    }

    var lesson: TutorialLesson { TutorialLesson.all[lessonIndex] }

    init() {
        game = Game(board: TutorialLesson.all[0].board, sideToMove: .black)
    }

    var targets: Set<Square> {
        guard let sel = selected, phase == .playing else { return [] }
        return Set(game.legalMoves(from: sel).map(\.to))
    }

    var forcedTargets: Set<Square> {
        guard let sel = selected, phase == .playing else { return [] }
        return Set(
            game.legalMoves(from: sel)
                .filter { Rules.isForcedCapture($0, on: game.board) }
                .map(\.to)
        )
    }

    func startLesson() {
        phase = .playing
        showHint = false
        selected = nil
        game = Game(board: lesson.board, sideToMove: .black)
    }

    func handleTap(_ sq: Square) {
        guard phase == .playing || phase == .wrong else { return }
        if phase == .wrong { phase = .playing }

        if let sel = selected {
            let candidates = game.legalMoves(from: sel).filter { $0.to == sq }
            if let move = candidates.first {
                // 튜토리얼에서는 프로모션 선택을 묻지 않고 퀸으로 자동 승격
                let chosen = candidates.first(where: { $0.promotion == .queen }) ?? move
                selected = nil
                submit(chosen)
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

    private func submit(_ move: Move) {
        guard lesson.isSuccess(move) else {
            Haptics.failure()
            phase = .wrong
            game = Game(board: lesson.board, sideToMove: .black)
            return
        }
        game.play(move)
        Haptics.move()

        if lesson.playsWhiteReply {
            // 백의 강제 응수를 자동 재생해 승리를 체험시킨다
            let snapshot = game
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 600_000_000)
                var g = snapshot
                if let reply = g.legalMoves().first {
                    g.play(reply)
                    self.game = g
                    Haptics.capture()
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
                Haptics.success()
                self.phase = .success
            }
        } else {
            Haptics.success()
            phase = .success
        }
    }

    func next() {
        if lessonIndex + 1 < TutorialLesson.all.count {
            lessonIndex += 1
            phase = .intro
            selected = nil
            game = Game(board: lesson.board, sideToMove: .black)
        } else {
            phase = .finished
        }
    }
}

struct TutorialView: View {
    @StateObject private var model = TutorialViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 14) {
                progressDots

                BoardView(
                    board: model.game.board,
                    lastMove: model.game.lastMove,
                    selected: model.selected,
                    targets: model.targets,
                    forcedTargets: model.forcedTargets,
                    onTap: model.handleTap
                )
                .padding(.horizontal, 12)
                .opacity(model.phase == .intro || model.phase == .finished ? 0.35 : 1)

                missionPanel
                Spacer(minLength: 0)
            }
            .padding(.top, 8)

            if model.phase == .intro { introCard }
            if model.phase == .finished { finishedCard }
        }
        .navigationTitle("배우기")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(TutorialLesson.all) { lesson in
                Circle()
                    .fill(lesson.id <= model.lessonIndex ? Theme.accent : Color(.systemGray4))
                    .frame(width: 8, height: 8)
            }
        }
    }

    @ViewBuilder
    private var missionPanel: some View {
        if model.phase == .playing || model.phase == .wrong || model.phase == .success {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(model.lesson.title)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Spacer()
                    if model.phase == .playing || model.phase == .wrong {
                        Button {
                            model.showHint.toggle()
                        } label: {
                            Label("힌트", systemImage: "lightbulb")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(Theme.accent)
                    }
                }

                switch model.phase {
                case .wrong:
                    Label("그 수가 아니에요. 다시 해보세요!", systemImage: "arrow.uturn.backward")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.coral)
                case .success:
                    Label("정답! 훌륭해요.", systemImage: "checkmark.circle.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.green)
                default:
                    Text(model.lesson.goal)
                        .font(.system(.subheadline, design: .rounded))
                }

                if model.showHint && model.phase != .success {
                    Text("💡 " + model.lesson.hint)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                if model.phase == .success {
                    Button {
                        model.next()
                    } label: {
                        Text(model.lessonIndex + 1 < TutorialLesson.all.count ? "다음 레슨" : "완료")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                }
            }
            .padding(18)
            .cardStyle()
            .padding(.horizontal, 16)
        }
    }

    private var introCard: some View {
        VStack(spacing: 16) {
            Text("레슨 \(model.lessonIndex + 1)")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.accent)
            Text(model.lesson.title)
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text(model.lesson.story)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                model.startLesson()
            } label: {
                Text("미션 시작")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
        }
        .padding(26)
        .frame(maxWidth: 330)
        .cardStyle()
        .padding(24)
    }

    private var finishedCard: some View {
        VStack(spacing: 16) {
            Text("🎓")
                .font(.system(size: 54))
            Text("모든 레슨 완료!")
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text("이기는 방법은 세 가지예요.\n① 킹만 남기기 ② 체크메이트 당하기 ③ 외딴 섬(체크가 아닌데 킹만 움직일 수 있는 상태) 만들기.\n이제 실전에서 만나요!")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                dismiss()
            } label: {
                Text("홈으로")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
        }
        .padding(26)
        .frame(maxWidth: 330)
        .cardStyle()
        .padding(24)
    }
}
