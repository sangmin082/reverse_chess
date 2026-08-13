import SwiftUI

/// 온라인 대전 로비 — 방 만들기 / 방코드로 입장, 매칭되면 대국 화면으로 전환
struct OnlineScreen: View {
    @StateObject private var client = RoomClient()
    @State private var joinCode = ""
    @State private var gameModel: GameViewModel?
    @FocusState private var codeFieldFocused: Bool

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            if let gameModel {
                GameScreen(model: gameModel)
            } else {
                lobby
            }
        }
        .navigationTitle("온라인 대전")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.paper, for: .navigationBar)
        .onChange(of: client.state) { _, newState in
            if case .matched(let me) = newState, gameModel == nil {
                gameModel = GameViewModel(mode: .online(me), client: client)
                Haptics.success()
            }
        }
        .onDisappear {
            client.close()
        }
    }

    // MARK: - 로비

    @ViewBuilder
    private var lobby: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch client.state {
            case .idle, .failed, .opponentLeft:
                entryView
            case .connecting:
                statusView(title: "연결 중…",
                           detail: "서버가 잠들어 있으면 깨우는 데 최대 1분 정도 걸릴 수 있어요.")
            case .waitingForOpponent(let code):
                waitingView(code: code)
            case .matched:
                statusView(title: "매칭 완료", detail: "대국을 시작합니다.")
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private var entryView: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("친구와 한 판")
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundStyle(Theme.ink)
                .padding(.top, 36)
            Rectangle().fill(Theme.accent).frame(width: 44, height: 3)

            Text("방을 만들어 코드를 공유하거나, 받은 코드로 입장하세요. 선공(흑)은 무작위로 정해집니다.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            if case .failed(let message) = client.state {
                Text(message)
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            if case .opponentLeft = client.state {
                Text("상대가 나가서 방이 닫혔습니다.")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }

            Button("방 만들기") {
                guard let url = OnlineConfig.resolvedServerURL() else { return }
                client.createRoom(serverURL: url)
            }
            .buttonStyle(InkButtonStyle(filled: true))

            VStack(alignment: .leading, spacing: 10) {
                Text("방코드로 입장")
                    .font(.system(.subheadline, design: .serif, weight: .bold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 10) {
                    TextField("ABC123", text: $joinCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($codeFieldFocused)
                        .font(.system(.title3, design: .monospaced, weight: .bold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(Theme.ink, lineWidth: 1.5)
                        )
                        .onChange(of: joinCode) { _, newValue in
                            joinCode = String(newValue.uppercased().prefix(6))
                        }

                    Button("입장") {
                        guard let url = OnlineConfig.resolvedServerURL(), joinCode.count == 6 else { return }
                        codeFieldFocused = false
                        client.joinRoom(code: joinCode, serverURL: url)
                    }
                    .buttonStyle(InkButtonStyle())
                    .frame(width: 88)
                    .opacity(joinCode.count == 6 ? 1 : 0.4)
                }
            }
            .padding(.top, 6)
        }
    }

    private func waitingView(code: String) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("방이 열렸습니다")
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundStyle(Theme.ink)
                .padding(.top, 36)
            Rectangle().fill(Theme.accent).frame(width: 44, height: 3)

            Text("친구에게 이 코드를 보내주세요. 입장하는 즉시 대국이 시작됩니다.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)

            // 방코드
            HStack {
                Spacer()
                Text(code)
                    .font(.system(size: 46, weight: .black, design: .monospaced))
                    .foregroundStyle(Theme.ink)
                    .kerning(6)
                Spacer()
            }
            .padding(.vertical, 22)
            .panelStyle()

            ShareLink(item: "리버스 체스에서 한 판 하자! 방코드: \(code)") {
                Text("코드 공유하기")
                    .font(.system(.body, weight: .semibold))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Theme.paper)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Theme.ink))
            }

            HStack(spacing: 8) {
                ProgressView().tint(Theme.inkSoft)
                Text("상대를 기다리는 중…")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
            }

            Button("취소") { client.close() }
                .buttonStyle(InkButtonStyle())
        }
    }

    private func statusView(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundStyle(Theme.ink)
                .padding(.top, 36)
            Rectangle().fill(Theme.accent).frame(width: 44, height: 3)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            ProgressView().tint(Theme.inkSoft)
        }
    }
}
