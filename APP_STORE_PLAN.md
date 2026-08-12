# 리버스 체스 — App Store 출시 플랜

> 대상: https://reversechess.perfect.ai.kr 의 iOS App Store 버전
> 작성일: 2026-08-12

> **진행 상황 (2026-08-12):** Phase 1 완료 — Capacitor iOS 프로젝트 구성,
> 웹 자산 로컬 번들(GA 제거·폰트 오프라인화), 앱 아이콘/스플래시,
> GitHub Actions 빌드/TestFlight 파이프라인까지 구현됨. 자세한 사용법은 [README](./README.md) 참고.

## 1. 현재 상태 분석

웹 버전을 분석한 결과:

| 항목 | 내용 |
|---|---|
| 기술 스택 | React + Vite SPA, React Router |
| 라우트 | `/` (홈), `/single/:difficulty` (AI 대전 쉬움/어려움), `/two` (로컬 2인 대전), `/tutorial` |
| AI 엔진 | 클라이언트 사이드 자체 엔진 (Web Worker, depth 기반 탐색) |
| 백엔드 | 없음 — 완전 정적 사이트, 로그인/온라인 대전 없음 |
| 저장소 | localStorage 사용 |
| 분석 도구 | Google Analytics (gtag) |
| 기타 | 한국어 UI, `viewport-fit=cover` 이미 적용됨 |

**중요:** 현재 이 GitHub 레포에는 소스 코드가 없습니다 (README만 존재).
앱 작업을 시작하려면 먼저 웹 버전의 소스 코드를 이 레포(또는 원본 레포)에서 작업할 수 있어야 합니다.

## 2. 접근 방식 결정

### 권장: Capacitor로 기존 웹 앱 패키징 ✅

| 방식 | 장점 | 단점 | 판정 |
|---|---|---|---|
| **Capacitor** | 기존 React 코드 95% 재사용, 1~2주 내 완성 가능, 네이티브 API(햅틱, Game Center 등) 접근 가능 | 네이티브 대비 미세한 성능 차이 (체스 게임엔 무관) | **권장** |
| React Native 재작성 | 완전한 네이티브 UX | 전체 재작성 필요 (수개월), 유지보수 이원화 | 비권장 |
| 단순 WebView 래퍼 (URL 로드) | 가장 빠름 | **Apple 심사 가이드라인 4.2 (최소 기능성) 리젝 확률 매우 높음** | 금지 |

핵심: Capacitor는 웹 자산을 **앱 안에 로컬로 번들**하므로 오프라인에서 완전히 동작하고,
단순 웹사이트 래퍼가 아니라 네이티브 기능이 추가된 앱으로 심사받을 수 있습니다.
게임 로직이 전부 클라이언트에 있는 현재 구조가 Capacitor에 이상적입니다.

## 3. 사전 준비물

- [ ] **Apple Developer Program 가입** — 연 $99 (개인 또는 법인). 가입 승인에 1~2일 소요
- [ ] **macOS 머신 + Xcode** — iOS 빌드는 Mac에서만 가능. Mac이 없으면 GitHub Actions(macOS 러너) 또는 클라우드 Mac 서비스로 대체 가능
- [ ] **웹 버전 소스 코드**를 이 레포에 push (모노레포로 웹+앱 관리 권장)
- [ ] **개인정보처리방침 페이지 URL** — 심사 필수 항목 (예: `https://reversechess.perfect.ai.kr/privacy`)
- [ ] 테스트용 실기기 iPhone 1대 이상

## 4. 단계별 플랜

### Phase 1 — Capacitor 통합 (2~3일)

1. 소스 레포에 Capacitor 추가
   ```bash
   npm install @capacitor/core @capacitor/cli
   npx cap init "리버스 체스" kr.ai.perfect.reversechess --web-dir=dist
   npm install @capacitor/ios
   npm run build && npx cap add ios && npx cap sync
   ```
2. React Router를 **BrowserRouter → HashRouter**(또는 Capacitor 호환 설정)로 조정 — 파일 프로토콜에서 라우팅 깨짐 방지
3. 로컬 번들 기준으로 전 기능 오프라인 동작 확인 (AI 대전 Web Worker 포함)
4. Xcode 시뮬레이터 + 실기기에서 스모크 테스트

### Phase 2 — 네이티브 UX 다듬기 (3~5일)

- [ ] **앱 아이콘** (1024×1024 원본에서 자동 생성) + **스플래시 스크린** (`@capacitor/splash-screen`)
- [ ] **Safe Area 대응** — 노치/다이나믹 아일랜드 (이미 `viewport-fit=cover` 적용되어 있어 CSS `env(safe-area-inset-*)`만 점검)
- [ ] **햅틱 피드백** (`@capacitor/haptics`) — 기물 이동/캡처/승리 시. 심사 4.2 대응에도 도움
- [ ] **상태바 스타일** (`@capacitor/status-bar`) — 다크/라이트 배경에 맞춤
- [ ] 화면 회전 정책 결정 (세로 고정 권장)
- [ ] 스와이프 뒤로가기·당겨서 새로고침·텍스트 선택·더블탭 줌 등 **웹 제스처 비활성화**
- [ ] 게임 진행 중 앱 백그라운드 전환 시 상태 보존 (localStorage → Capacitor Preferences 이전 검토)

### Phase 3 — 심사 리스크 대응 (2~3일)

**가이드라인 4.2 (최소 기능성) — 가장 큰 리젝 리스크**
- 웹사이트를 그대로 감싼 앱으로 보이지 않도록 네이티브 기능을 최소 2~3개 추가:
  - 햅틱 피드백 (Phase 2에서 완료)
  - **Game Center 리더보드/업적** — AI 격파, 튜토리얼 완료 등. 게임 앱 심사에 강력한 플러스
  - 오프라인 완전 동작 (로컬 번들이므로 자동 충족)

**개인정보 / 추적**
- Google Analytics(gtag)는 앱에서 그대로 쓰면 **App Tracking Transparency(ATT)와 개인정보 라벨 신고** 이슈가 생김
- 권장: 앱 빌드에서는 **GA 제거** (조건부 빌드) — 로그인도 서버도 없는 게임이라 "데이터 수집 없음"으로 신고 가능, 심사가 가장 깔끔
- 대안: Firebase Analytics로 교체 후 개인정보 라벨에 정확히 신고

**메타데이터 준비**
- [ ] 앱 이름: "리버스 체스" (App Store 내 중복 확인 필요)
- [ ] 부제목 (30자), 설명, 키워드 (안티체스, 체스 변형, 보드게임 등)
- [ ] 스크린샷: 6.9" (iPhone Pro Max) 필수, iPad 지원 시 13" 추가
- [ ] 연령 등급: 4+ 예상 (설문 작성)
- [ ] 지원 URL + 개인정보처리방침 URL
- [ ] 카테고리: 게임 > 보드

### Phase 4 — 빌드 & 제출 (1주, 심사 대기 포함)

1. App Store Connect에서 앱 등록 (Bundle ID: `kr.ai.perfect.reversechess`)
2. Xcode Archive → **TestFlight 내부 테스트** 배포, 실기기 QA
3. 문제 없으면 심사 제출
4. 심사 소요: 통상 24~48시간 (리젝 시 수정 후 재제출 왕복 감안해 1주 버퍼)
5. 승인 후 수동/자동 출시 선택

### Phase 5 — 출시 후 (선택 사항)

- **Android / Google Play**: Capacitor라 `npx cap add android`로 대부분 재사용 (등록비 $25 일회성)
- 온라인 멀티플레이 (서버 필요 — 별도 프로젝트 규모)
- 난이도 추가, 기보 저장/복기 기능
- 인앱 결제(테마, 광고 제거 등) — 수익화 시 Apple 수수료 15~30% 고려
- CI/CD: GitHub Actions로 빌드 자동화 (fastlane)

## 5. 예상 일정 & 비용 요약

| 항목 | 예상 |
|---|---|
| 총 개발 기간 | **2~3주** (Phase 1~4, 파트타임 기준) |
| Apple Developer Program | $99/년 |
| 기타 비용 | 없음 (서버 불필요, 기존 코드 재사용) |

## 6. 주요 리스크

1. **심사 4.2 리젝** — 웹 래퍼로 판정될 위험. → Game Center + 햅틱 + 오프라인으로 대응. 리젝돼도 기능 보강 후 재심사 가능
2. **소스 코드 부재** — 현재 레포가 비어 있음. 웹 소스 확보가 첫 선결 과제
3. **Mac/Xcode 접근성** — 없으면 CI 기반 빌드 파이프라인 구성 필요
4. **개인정보 라벨 오신고** — GA 유지 시 정확한 신고 필수. 앱 빌드에서 제거가 가장 안전

## 7. 바로 시작할 다음 액션

1. 웹 버전 소스 코드를 이 레포에 push
2. Apple Developer Program 가입 신청
3. Phase 1 (Capacitor 통합) 착수
