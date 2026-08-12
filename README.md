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

`.github/workflows/ios.yml`:

- **push / PR** → macOS 러너에서 서명 없이 컴파일 검증 (Apple 계정 불필요)
- **수동 실행 (workflow_dispatch) + `testflight` 체크** → 서명 후 TestFlight 업로드

TestFlight 업로드에 필요한 레포 시크릿:

| 시크릿 | 내용 |
|---|---|
| `APPLE_TEAM_ID` | Apple Developer 팀 ID |
| `BUILD_CERTIFICATE_BASE64` | Apple Distribution 인증서(.p12)의 base64 |
| `P12_PASSWORD` | .p12 비밀번호 |
| `APPSTORE_API_KEY_ID` | App Store Connect API 키 ID |
| `APPSTORE_API_ISSUER_ID` | App Store Connect API Issuer ID |
| `APPSTORE_API_PRIVATE_KEY` | API 개인 키(.p8) 파일 내용 전체 |

사전 준비 (1회):

1. [Apple Developer Program](https://developer.apple.com/programs/) 가입 ($99/년)
2. App Store Connect에서 앱 등록 (Bundle ID `com.reversechess.game`)
3. 인증서/API 키 발급 후 위 시크릿 등록
4. Actions 탭 → iOS → Run workflow → `testflight` 체크 → 실행

### Mac 없이 Distribution 인증서(.p12) 만들기

인증서 발급은 보통 키체인(Mac)으로 하지만, OpenSSL만 있으면 어디서든 가능하다
(Linux, WSL, Git Bash 등):

```bash
# 1. 개인 키 + CSR(인증서 서명 요청) 생성
openssl genrsa -out dist.key 2048
openssl req -new -key dist.key -out dist.csr \
  -subj "/emailAddress=본인이메일/CN=본인이름/C=KR"

# 2. https://developer.apple.com/account/resources/certificates 에서
#    Certificates → + → "Apple Distribution" 선택 → dist.csr 업로드
#    → distribution.cer 다운로드

# 3. .cer + 개인 키 → .p12 로 합치기 (비밀번호를 정하고 P12_PASSWORD 시크릿에 등록)
openssl x509 -inform DER -in distribution.cer -out distribution.pem
openssl pkcs12 -export -legacy \
  -inkey dist.key -in distribution.pem -out certificate.p12
# openssl 1.x 등에서 -legacy 옵션이 없다는 에러가 나면 -legacy를 빼고 실행

# 4. BUILD_CERTIFICATE_BASE64 시크릿에 넣을 값 생성
base64 -w0 certificate.p12   # macOS라면: base64 -i certificate.p12
```

`dist.key`와 `certificate.p12`는 유출되면 앱 서명을 도용당할 수 있으니
시크릿 등록 후 안전한 곳에 보관하거나 삭제할 것.
