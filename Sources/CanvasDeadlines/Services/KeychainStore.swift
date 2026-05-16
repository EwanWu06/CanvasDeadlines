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

    // MARK: - iCal Feed URL（含私密 token，按凭据保护）

    static func saveFeedURL(_ url: String) throws { try set(url, account: feedAccount) }
    static func loadFeedURL() -> String? { get(account: feedAccount) }
    static func deleteFeedURL() throws { try remove(account: feedAccount) }

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
