import Foundation
import Security

/// Manages secure storage of API keys in the macOS Keychain
/// Uses the Security framework to store sensitive credentials safely
/// 
/// Why use Keychain:
/// - API keys are encrypted by the system
/// - Keys persist across app launches
/// - Keys are protected by macOS security
/// - Keys are NOT stored in plain text files or UserDefaults
/// 
/// Each API key is associated with an AdversarialTestConfig.ID
/// This allows different configurations to have different API keys
/// 
/// Thread-safe: All operations are synchronous and safe to call from any thread
/// Singleton: Use KeychainManager.shared to access
final class KeychainManager {
    /// Shared singleton instance
    /// Use this instead of creating new instances
    static let shared = KeychainManager()
    
    /// Private initializer enforces singleton pattern
    private init() {}

    /// Service identifier for Keychain items
    /// All API keys are stored under this service name
    /// This groups all Patience API keys together in Keychain Access.app
    private let service = "com.patience.security.apiKeys"

    /// Saves an API key in the keychain associated with the given AdversarialTestConfig.ID
    /// If a key already exists for this ID, it will be updated
    /// 
    /// - Parameters:
    ///   - id: The AdversarialTestConfig.ID to associate with the API key
    ///   - key: The API key string to save (e.g., OpenAI API key, Anthropic API key)
    /// - Returns: true if the save operation was successful, false otherwise
    /// 
    /// How it works:
    /// 1. Converts key string to Data
    /// 2. Checks if item already exists in Keychain
    /// 3. If exists: Updates the existing item with new key
    /// 4. If not exists: Adds new item to Keychain
    /// 
    /// Keychain attributes:
    /// - kSecClass: kSecClassGenericPassword (stores as generic password)
    /// - kSecAttrService: "com.patience.security.apiKeys" (groups all Patience keys)
    /// - kSecAttrAccount: config ID as string (unique identifier for this key)
    /// - kSecValueData: encrypted key data
    func saveAPIKey(for id: AdversarialTestConfig.ID, key: String) -> Bool {
        guard let keyData = key.data(using: .utf8) else {
            return false
        }

        // Build query dictionary to identify this specific Keychain item
        // CFString keys are required by Security framework
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,  // Type: generic password
            kSecAttrService: service,              // Service: com.patience.security.apiKeys
            kSecAttrAccount: id.uuidString         // Account: unique config ID
        ]

        // Check if item already exists in Keychain
        // Try to find existing item
        // SecItemCopyMatching returns errSecSuccess if found, errSecItemNotFound if not
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            // Item exists - update it with new key data
            // Only update the data, keep other attributes the same
            let attributesToUpdate: [CFString: Any] = [
                kSecValueData: keyData  // New encrypted key data
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            return updateStatus == errSecSuccess  // true if update succeeded
        } else if status == errSecItemNotFound {
            // Item doesn't exist - add new item to Keychain
            // Start with query attributes and add the data
            var newItem = query
            newItem[kSecValueData] = keyData  // Encrypted key data
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            return addStatus == errSecSuccess  // true if add succeeded
        } else {
            // Unexpected error (permissions, etc.)
            return false
        }
    }

    /// Retrieves an API key from the keychain associated with the given AdversarialTestConfig.ID
    /// 
    /// - Parameter id: The AdversarialTestConfig.ID to retrieve the API key for
    /// - Returns: The API key string if found, nil if not found or error occurred
    /// 
    /// How it works:
    /// 1. Queries Keychain for item matching the config ID
    /// 2. If found, retrieves the encrypted data
    /// 3. Converts data back to string
    /// 4. Returns the decrypted API key
    /// 
    /// Returns nil if:
    /// - No key exists for this ID
    /// - Keychain access denied
    /// - Data cannot be converted to string
    func apiKey(for id: AdversarialTestConfig.ID) -> String? {
        // Build query to find and retrieve the key data
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,  // Type: generic password
            kSecAttrService: service,              // Service: com.patience.security.apiKeys
            kSecAttrAccount: id.uuidString,        // Account: unique config ID
            kSecReturnData: true,                  // Return the actual data (not just attributes)
            kSecMatchLimit: kSecMatchLimitOne      // Only return one item (should be unique anyway)
        ]

        // Variable to receive the result
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        // Check if retrieval succeeded and convert data to string
        guard status == errSecSuccess,           // Found the item
              let data = item as? Data,          // Got data back
              let key = String(data: data, encoding: .utf8) else {  // Converted to string
            return nil  // Not found or conversion failed
        }

        return key  // Return the decrypted API key
    }

    /// Deletes an API key from the keychain associated with the given AdversarialTestConfig.ID
    /// 
    /// - Parameter id: The AdversarialTestConfig.ID to delete the API key for
    /// - Returns: true if the deletion was successful or item didn't exist, false on error
    /// 
    /// How it works:
    /// 1. Queries Keychain for item matching the config ID
    /// 2. Deletes the item if found
    /// 
    /// Returns true if:
    /// - Item was successfully deleted (errSecSuccess)
    /// - Item didn't exist anyway (errSecItemNotFound)
    /// 
    /// Returns false if:
    /// - Keychain access denied
    /// - Other unexpected error
    func deleteAPIKey(for id: AdversarialTestConfig.ID) -> Bool {
        // Build query to identify the item to delete
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,  // Type: generic password
            kSecAttrService: service,              // Service: com.patience.security.apiKeys
            kSecAttrAccount: id.uuidString         // Account: unique config ID
        ]

        // Attempt to delete the item
        let status = SecItemDelete(query as CFDictionary)
        
        // Success if deleted or if it didn't exist
        // Both cases mean the key is no longer in Keychain
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
