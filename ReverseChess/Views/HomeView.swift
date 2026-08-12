import SwiftUI

struct HomeView: View {
    @State private var botLevel: BotLevel = .easy
    @State private var showRules = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    wordmark
                        .padding(.top, 48)

                    Spacer()

                    menu

                    Spacer()

                    Button {
                        showRules = true
                    } label: {
                        Text("규칙 한 장 보기")
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSoft)
                            .underline()
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 28)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showRules) { rulesSheet }
        }
        .tint(Theme.ink)
    }

    // MARK: - 워드마크

    private var wordmark: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 뒤집힌 킹 — 패배가 곧 승리
            Text("♚\u{FE0E}")
                .font(.system(size: 56))
                .foregroundStyle(Theme.ink)
                .rotationEffect(.degrees(180))

            Text("리버스 체스")
                .font(.system(size: 42, weight: .black, design: .serif))
                .foregroundStyle(Theme.ink)

            Text("지는 법을 아는 사람이 이깁니다")
                .font(.system(.body, design: .serif))
                .italic()
                .foregroundStyle(Theme.inkSoft)
        }
    }

    // MARK: - 메뉴

    private var menu: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuRow(title: "배우기", detail: "여섯 개의 미션으로 규칙 익히기") {
                TutorialView()
            }
            menuRow(title: "컴퓨터 대전", detail: "혼자서 한 판") {
                GameScreen(mode: .vsBot(botLevel))
            }

            // 난이도: 텍스트 토글
            HStack(spacing: 20) {
                ForEach(BotLevel.allCases) { level in
                    Button {
                        botLevel = level
                    } label: {
                        Text(level.korean)
                            .font(.system(.subheadline, weight: botLevel == level ? .bold : .regular))
                            .foregroundStyle(botLevel == level ? Theme.accent : Theme.inkSoft)
                            .overlay(alignment: .bottom) {
                                if botLevel == level {
                                    Rectangle()
                                        .fill(Theme.accent)
                                        .frame(height: 2)
                                        .offset(y: 4)
                                }
                            }
                    }
                }
                Spacer()
            }
            .padding(.leading, 2)
            .padding(.top, 2)
            .padding(.bottom, 18)

            menuRow(title: "함께 하기", detail: "한 기기로 번갈아 두기") {
                GameScreen(mode: .twoPlayer)
            }
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }

    private func menuRow<Destination: View>(
        title: String, detail: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
            NavigationLink {
                destination()
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.system(size: 27, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.vertical, 18)
                .contentShape(Rectangle())
            }
        }
    }

    // MARK: - 규칙 시트

    private var rulesSheet: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                Text("규칙 한 장")
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 28)

                VStack(alignment: .leading, spacing: 12) {
                    ruleLine("흑이 먼저 둡니다.")
                    ruleLine("킹만 남기고 모든 기물을 잃으면 승리합니다.")
                    ruleLine("잡을 수 있는 수가 있으면 반드시 잡아야 합니다. 단, 퀸의 캡처는 2칸 이내일 때만 강제입니다.")
                    ruleLine("체크 규칙은 그대로— 체크 피하기가 강제 캡처보다 우선합니다.")
                    ruleLine("체크메이트를 당한 쪽이 이깁니다.")
                    ruleLine("체크가 아닌데 킹밖에 움직일 수 없다면, 그것도 승리입니다. (외딴 섬)")
                    ruleLine("스테일메이트, 3회 동형, 50수는 무승부입니다.")
                    ruleLine("프로모션은 있고, 캐슬링과 앙파상은 없습니다.")
                }

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .presentationDetents([.large])
    }

    private func ruleLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("—")
                .foregroundStyle(Theme.accent)
                .font(.system(.body, weight: .bold))
            Text(text)
                .font(.system(.callout))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
