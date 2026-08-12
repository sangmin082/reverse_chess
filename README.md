# 리버스 체스 — iOS

져야 이기는 체스. SwiftUI로 만든 네이티브 iOS 게임.

- Bundle ID: `com.reversechess.game`
- 완전 오프라인 · 데이터 수집 없음
- 출시 플랜: [APP_STORE_PLAN.md](./APP_STORE_PLAN.md)

## 게임 규칙

- **흑이 선공.** 초기 배치는 킹·퀸이 백과 거울 대칭 (백 d1 퀸 / 흑 d8 킹)
- **킹만 남기고 모든 기물을 잃으면 승리**
- **강제 캡처**: 잡을 수 있는 합법수가 있으면 반드시 그중 하나를 둬야 함.
  단, 퀸의 캡처는 가로·세로·대각선 **2칸 이내**일 때만 강제 대상
- **체크 규칙은 기본 체스와 동일**하며, 체크 피하기가 강제 캡처보다 우선.
  **체크메이트를 당한 쪽이 승리**
- **외딴 섬**: 체크가 아닌데 움직일 수 있는 기물이 킹뿐이면 그 플레이어 승리
- 무승부: 스테일메이트 · 3회 동형 · 50수 규칙
- 프로모션 있음 (퀸/룩/비숍/나이트), 캐슬링·앙파상 없음

## 앱 구성

```
ReverseChess/
  App/       ReverseChessApp.swift
  Engine/    ChessCore.swift(타입·보드) Rules.swift(수 생성·강제캡처·체크) Game.swift(진행·종료 판정)
  AI/        Bot.swift (네가맥스+알파베타, 쉬움/어려움)
  Views/     HomeView / GameScreen / BoardView / TutorialView(미션형 6레슨) / Theme / Haptics
```

- **배우기**: 미션 기반 인터랙티브 튜토리얼 — 각 레슨에서 직접 정답 수를 찾아야 통과
- **컴퓨터 대전**: 쉬움/어려움 (사람이 흑, 선공)
- **함께 하기**: 한 기기로 로컬 2인 대전

## 빌드

로컬(Mac): `ReverseChess.xcodeproj`를 Xcode 16+로 열고 실행.

CI (GitHub Actions):

- `.github/workflows/ios.yml` — push/PR 시 서명 없이 컴파일 검증
- `.github/workflows/testflight.yml` — main 푸시 또는 수동 실행 시 서명 후 TestFlight 업로드
  (fastlane match 사용, Mac 불필요)

TestFlight 배포용 시크릿 7개 (feast_of_memory와 동일 구성, 등록 완료됨):
`APP_STORE_CONNECT_KEY_ID` `APP_STORE_CONNECT_ISSUER_ID` `APP_STORE_CONNECT_KEY`
`APPLE_TEAM_ID` `MATCH_GIT_URL` `MATCH_GIT_BASIC_AUTHORIZATION` `MATCH_PASSWORD`
