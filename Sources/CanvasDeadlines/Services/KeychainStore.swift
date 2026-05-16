import Foundation
import Security

enum KeychainError: LocalizedError {
    case unexpectedData
    case status(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unexpectedData: return "Keychain 中数据格式异常。"
        case .status(let code): return "Keychain 操作失败（OSStatus \(code)）。"
        }
    }
}

enum KeychainStore {
    private static let service = "com.ewanwu.CanvasDeadlines"
    private static let feedAccount = "canvas-ical-feed-url"

    private static let feedsAccount = "canvas-ical-feeds-json"

    // MARK: - 多个 iCal 订阅源（含私密标识，按凭据保护）

    static func loadFeeds() -> [Feed] {
        // 新格式：JSON 数组
        if let json = get(account: feedsAccount),
           let data = json.data(using: .utf8),
           let feeds = try? JSONDecoder().decode([Feed].self, from: data) {
            return feeds
        }
        // 迁移：旧的单条 feed URL → 包成一条
        if let legacy = get(account: feedAccount), !legacy.isEmpty {
            let migrated = [Feed(label: "UCLA Extension", url: legacy)]
            try? saveFeeds(migrated)
            try? remove(account: feedAccount)
            return migrated
        }
        return []
    }

    static func saveFeeds(_ feeds: [Feed]) throws {
        let data = try JSONEncoder().encode(feeds)
        guard let json = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        try set(json, account: feedsAccount)
    }

    static func clearFeeds() throws {
        try remove(account: feedsAccount)
        try? remove(account: feedAccount)
    }

    // MARK: - 旧单条接口（Onboarding 首次保存仍可用，内部转为多源）

    static func saveFeedURL(_ url: String) throws {
        var feeds = loadFeeds()
        if feeds.isEmpty {
            feeds = [Feed(label: "我的 Canvas", url: url)]
        } else {
            feeds[0].url = url
        }
        try saveFeeds(feeds)
    }
    static func loadFeedURL() -> String? { loadFeeds().first?.url }
    static func deleteFeedURL() throws { try clearFeeds() }

    // MARK: - Generic implementation

    private static func set(_ value: String, account: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus != errSecSuccess { throw KeychainError.status(addStatus) }
        default:
            throw KeychainError.status(updateStatus)
        }
    }

    private static func get(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }

    private static func remove(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.status(status)
        }
    }
}
