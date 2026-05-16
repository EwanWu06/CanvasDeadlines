import Foundation

/// 一个 Canvas 日历订阅源。多校支持：UCLA Extension / SMC / WLAC 各一条。
struct Feed: Codable, Identifiable, Hashable {
    var id: UUID
    var label: String   // 学校/来源名，用户可自定义，如 "UCLA Extension"、"SMC"
    var url: String      // .ics / webcal 链接（含私密标识，存 Keychain）

    init(id: UUID = UUID(), label: String, url: String) {
        self.id = id
        self.label = label
        self.url = url
    }
}
