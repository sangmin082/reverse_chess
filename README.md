# 리버스 체스 — iOS 앱

[리버스 체스 웹 버전](https://reversechess.perfect.ai.kr)의 App Store 배포용 Capacitor 프로젝트.

- 출시 플랜: [APP_STORE_PLAN.md](./APP_STORE_PLAN.md)
- Bundle ID: `com.reversechess.game`

## 구조

```
www/                  # 앱에 번들되는 웹 자산 (라이브 사이트 미러 + 앱용 변환)
ios/                  # Capacitor가 생성한 Xcode 프로젝트 (App.xcodeproj, SPM 기반)
scripts/sync-web.mjs  # 라이브 사이트 → www/ 미러링 스크립트
.github/workflows/ios.yml  # CI: 비서명 빌드 검증 + TestFlight 업로드
```

웹 소스 코드는 아직 이 레포에 없다. `www/`는 배포된 사이트의 빌드 산출물을
미러링한 것이며, 앱용으로 두 가지가 변환되어 있다:

1. **Google Analytics 제거** — 앱 빌드는 데이터를 수집하지 않는다 (개인정보 라벨 "수집 안 함"으로 신고 가능). 번들이 `window.gtag`를 직접 호출하므로 no-op 스텁이 주입되어 있다.
2. **Google Fonts 로컬 번들** — `www/assets/fonts/` (Cinzel + Noto Sans KR). 완전 오프라인 동작.

웹 버전이 업데이트되면:

```bash
npm run sync:web   # 라이브 사이트 재미러링
npm run sync:ios   # www/ → iOS 프로젝트 복사
```

웹 소스가 레포에 들어오면 `sync:web` 대신 `vite build --outDir www`로 대체하면 된다.

## 로컬 개발 (Mac)

```bash
npm install
npm run sync:ios
npm run open:ios   # Xcode에서 열기 → 시뮬레이터/실기기 실행
```

## CI (GitHub Actions)

- `.github/workflows/ios.yml` — **push / PR** 시 macOS 러너에서 서명 없이 컴파일 검증 (Apple 계정 불필요)
- `.github/workflows/testflight.yml` — **수동 실행 또는 main 푸시** 시 서명 후 TestFlight 업로드

## TestFlight 배포 (Mac 불필요 — feast_of_memory와 동일 구성)

인증서/프로비저닝 프로파일은 [fastlane match](https://docs.fastlane.tools/actions/match/)가
CI에서 자동 생성해 별도 private repo에 보관하므로 Mac이 전혀 필요 없다.
시크릿 이름·형식이 [feast_of_memory](https://github.com/sangmin082/feast_of_memory)와 동일하므로,
거기서 쓰던 값을 **그대로 복사해 등록하면 된다** (인증서 repo도 공유 가능 —
match가 `com.reversechess.game`용 프로파일을 같은 repo에 추가로 만들어 관리한다).

### 사전 준비 (1회)

1. **Apple Developer Program 가입** — [developer.apple.com](https://developer.apple.com) (연 $99)
2. **번들 ID 등록** — Certificates, Identifiers & Profiles → Identifiers → `+` → App IDs → `com.reversechess.game`
3. **App Store Connect에 앱 생성** — [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → 나의 앱 → `+` → 위 번들 ID 선택
4. 아래 시크릿 재료가 없다면 (feast_of_memory에서 이미 만들었다면 재사용):
   - **App Store Connect API 키** — Users and Access → Integrations → App Store Connect API → Team Keys → `+` (Role: **App Manager**) → Issuer ID·Key ID 기록, `.p8` 다운로드(단 한 번만 가능!)
   - **Team ID** — developer.apple.com → Membership 페이지
   - **인증서 보관용 private repo** — 예: `ios-certificates` (빈 저장소)
   - **GitHub PAT** — Settings → Developer settings → Personal access tokens (classic) → `repo` 권한

### GitHub Secrets 등록

이 저장소 → Settings → Secrets and variables → Actions → New repository secret:

| Secret | 값 |
|---|---|
| `APP_STORE_CONNECT_KEY_ID` | API 키의 Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | API 키의 Issuer ID |
| `APP_STORE_CONNECT_KEY` | `.p8` 파일을 **base64 인코딩**한 문자열 (`base64 -w0 AuthKey_XXX.p8`) |
| `APPLE_TEAM_ID` | Team ID (예: `AB12CD34EF`) |
| `MATCH_GIT_URL` | 인증서 repo 주소 (`https://github.com/<계정>/ios-certificates.git`) |
| `MATCH_GIT_BASIC_AUTHORIZATION` | `echo -n "<깃허브계정>:<PAT>" \| base64 -w0` 결과 |
| `MATCH_PASSWORD` | 인증서 암호화용 비밀번호 (feast_of_memory와 같은 값 사용) |

### 실행

Actions 탭 → **TestFlight** → Run workflow. 성공하면 10~30분 뒤 App Store Connect →
TestFlight 탭에 빌드가 나타난다. 내부 테스팅 그룹에 본인을 추가하고 iPhone의
**TestFlight 앱**에서 설치할 것.

> 💡 public repo는 GitHub Actions 무료 무제한. private으로 바꾸면 macOS 러너는 분당 과금 배율이 10배라 무료 한도(월 2,000분)로 매달 약 15~20회 빌드 가능.
