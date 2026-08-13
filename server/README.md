
## 온라인 대전

feast_of_memory와 같은 구조: 방을 만들면 6자리 방코드가 발급되고, 친구가 코드로
입장하면 대국이 시작된다. 선공(흑)은 서버가 무작위 배정한다.

- `server/` — Node WebSocket 릴레이 서버. 무브를 해석하지 않고 상대에게 전달만 한다
  (엔진이 결정적이라 같은 무브 스트림이면 양쪽 상태가 항상 일치).
  방 정보는 메모리에만 있으며 대국 종료 시 즉시 삭제된다.
- `ReverseChess/Online/` — `RoomClient`(WebSocket 클라이언트) + `OnlineConfig`(서버 주소)
- 로컬 테스트: `cd server && npm install && npm test`

### 서버 배포 (1회, 무료)

1. [render.com](https://render.com) 가입 → **New → Blueprint** → 이 저장소 연결 → 배포
   (`render.yaml`이 자동 인식됨, free 플랜)
2. 배포된 주소가 `wss://reverse-chess-server.onrender.com` 인지 확인.
   서비스 이름을 바꿨다면 `ReverseChess/Online/OnlineConfig.swift`의 주소도 수정
3. `https://<서비스이름>.onrender.com/privacy` 가 개인정보처리방침 페이지로 서빙되므로
   App Store Connect의 개인정보처리방침 URL로 사용 가능

> 무료 티어는 15분간 접속이 없으면 잠들며, 다음 접속 시 깨어나는 데 최대 1분 걸린다
> (앱 로비에 안내 문구 표시됨).
