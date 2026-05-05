import Foundation
import Security

struct KeychainHelper {
    private static let service = "com.ebird-hotspot-menubar"
    private static let apiKeyAccount = "ebird-api-key"
    private static let regionCodeAccount = "ebird-location-id"

    // MARK: - Save
    static func save(_ value: String, account: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String:   data
        ]
        SecItemDelete(query as CFDictionary) // delete existing before saving
        SecItemAdd(query as CFDictionary, nil)
    }

    // MARK: - Load
    static func load(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Delete
    static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Convenience
    static var apiKey: String? {
        get { load(account: apiKeyAccount) }
        set {
            if let value = newValue { save(value, account: apiKeyAccount) }
            else { delete(account: apiKeyAccount) }
        }
    }

    static var locationID: String? {
        get { load(account: regionCodeAccount) }
        set {
            if let value = newValue { save(value, account: regionCodeAccount) }
            else { delete(account: regionCodeAccount) }
        }
    }
}
