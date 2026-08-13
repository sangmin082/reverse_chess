import Foundation

/// 온라인 대전 서버 설정
enum OnlineConfig {
    /// 릴레이 서버 주소 — server/ 디렉터리를 Render에 배포한 주소.
    /// (render.yaml 의 서비스 이름을 바꾸면 여기도 함께 수정)
    static let defaultServerURLString = "wss://reverse-chess-server.onrender.com"

    static func resolvedServerURL() -> URL? {
        URL(string: defaultServerURLString)
    }
}
