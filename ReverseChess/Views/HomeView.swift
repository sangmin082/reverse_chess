import SwiftUI

struct HomeView: View {
    @State private var botLevel: BotLevel = .easy

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header
                            .padding(.top, 36)

                        VStack(spacing: 16) {
                            NavigationLink {
                                TutorialView()
                            } label: {
                                modeCard(
                                    icon: "graduationcap.fill",
                                    title: "배우기",
                                    subtitle: "미션을 풀며 규칙 익히기 · 6개 레슨"
                                )
                            }

                            VStack(spacing: 0) {
                                NavigationLink {
                                    GameScreen(mode: .vsBot(botLevel))
                                } label: {
                                    modeCardContent(
                                        icon: "cpu.fill",
                                        title: "컴퓨터 대전",
                                        subtitle: "AI를 상대로 한 판"
                                    )
                                }
                                Divider().padding(.horizontal, 18)
                                Picker("난이도", selection: $botLevel) {
                                    ForEach(BotLevel.allCases) { level in
                                        Text(level.korean).tag(level)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(16)
                            }
                            .cardStyle()

                            NavigationLink {
                                GameScreen(mode: .twoPlayer)
                            } label: {
                                modeCard(
                                    icon: "person.2.fill",
                                    title: "함께 하기",
                                    subtitle: "한 기기로 번갈아 두기"
                                )
                            }
                        }
                        .padding(.horizontal, 20)

                        rulesFootnote
                            .padding(.horizontal, 28)
                            .padding(.bottom, 30)
                    }
                }
            }
        }
        .tint(Theme.accent)
    }

    private var header: some View {
        VStack(spacing: 10) {
            // 뒤집힌 왕관 — "정반대의 체스"를 상징하는 로고 마크
            Image(systemName: "crown.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Theme.accent)
                .rotationEffect(.degrees(180))
                .padding(20)
                .background(Circle().fill(Theme.accentSoft))

            Text("리버스 체스")
                .font(.system(size: 34, weight: .heavy, design: .rounded))

            Text("기물을 다 버리는 사람이 이깁니다")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private func modeCard(icon: String, title: String, subtitle: String) -> some View {
        modeCardContent(icon: icon, title: title, subtitle: subtitle)
            .cardStyle()
    }

    private func modeCardContent(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accentSoft))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .contentShape(Rectangle())
    }

    private var rulesFootnote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("한눈에 보는 규칙")
                .font(.system(.footnote, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            Group {
                Text("· 흑이 먼저 두고, 킹만 남기면 승리")
                Text("· 잡을 수 있으면 반드시 잡아야 함 (퀸은 2칸 이내만 강제)")
                Text("· 체크 피하기가 강제 캡처보다 우선")
                Text("· 체크메이트를 당해도, 외딴 섬이 되어도 승리")
            }
            .font(.system(.caption, design: .rounded))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
