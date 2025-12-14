import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    private init() {}

    private let service = "com.patience.security.apiKeys"

    /// Saves an API key in the keychain associated with the given AdversarialTestConfig.ID.
    /// - Parameters:
    ///   - id: The AdversarialTestConfig.ID to associate with the API key.
    ///   - key: The API key string to save.
    /// - Returns: True if the save operation was successful, false otherwise.
    func saveAPIKey(for id: AdversarialTestConfig.ID, key: String) -> Bool {
        guard let keyData = key.data(using: .utf8) else {
            return false
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: id.uuidString
        ]

        // Check if item already exists
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            // Update existing item
            let attributesToUpdate: [CFString: Any] = [
                kSecValueData: keyData
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            return updateStatus == errSecSuccess
        } else if status == errSecItemNotFound {
            // Add new item
            var newItem = query
            newItem[kSecValueData] = keyData
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            return addStatus == errSecSuccess
        } else {
            return false
        }
    }

    /// Retrieves an API key from the keychain associated with the given AdversarialTestConfig.ID.
    /// - Parameter id: The AdversarialTestConfig.ID to retrieve the API key for.
    /// - Returns: The API key string if found, nil otherwise.
    func apiKey(for id: AdversarialTestConfig.ID) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: id.uuidString,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    /// Deletes an API key from the keychain associated with the given AdversarialTestConfig.ID.
    /// - Parameter id: The AdversarialTestConfig.ID to delete the API key for.
    /// - Returns: True if the deletion was successful, false otherwise.
    func deleteAPIKey(for id: AdversarialTestConfig.ID) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: id.uuidString
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
