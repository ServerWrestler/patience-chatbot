import Foundation
import Security

/// Manages secure storage of secrets (API keys, target-bot credentials) in the macOS Keychain.
/// Uses the Security framework so sensitive material is encrypted at rest by the system and
/// never written to UserDefaults, configs, or exported JSON.
///
/// Why Keychain:
/// - Secrets are encrypted by the system and protected by macOS security.
/// - They persist across launches without living in plain-text preference plists.
/// - `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` keeps them on THIS device — they never
///   sync to iCloud Keychain and are excluded from encrypted backups. For a security tool
///   that's the correct posture: credentials should not travel off the machine they're used on.
///
/// Account namespacing (see `Account`): a single config can own more than one secret (an
/// adversarial-bot key AND a judge key), and scenario configs are a separate ID space, so each
/// secret is stored under a distinct, collision-free account string.
///
/// Thread-safe: SecItem operations are synchronous and safe to call from any thread.
/// Singleton: use `KeychainManager.shared`.
final class KeychainManager {
    /// Shared singleton instance.
    static let shared = KeychainManager()

    /// Private initializer enforces the singleton pattern.
    private init() {}

    /// Service identifier grouping all Patience secrets in Keychain Access.app.
    private let service = "com.patience.security.apiKeys"

    // MARK: - Account namespacing

    /// Builds the Keychain account string for each kind of secret. Centralizing this here keeps
    /// the naming scheme in one place and prevents two secret kinds from colliding on one ID.
    enum Account {
        /// Adversarial-bot provider key. Unchanged from the original scheme (bare UUID) so
        /// secrets stored by earlier builds remain retrievable.
        static func adversarialBot(_ id: AdversarialTestConfig.ID) -> String { id.uuidString }

        /// Judge/critic provider key — a second secret owned by the same adversarial config.
        static func judge(_ id: AdversarialTestConfig.ID) -> String { "\(id.uuidString).judge" }

        /// Scenario target-bot credential. Prefixed to stay clear of the adversarial UUID space.
        static func scenarioBot(_ id: TestConfig.ID) -> String { "scenario.\(id.uuidString)" }
    }

    // MARK: - Generic secret storage

    /// Stores (or updates) a secret under `account`. Returns false on encoding failure or any
    /// Keychain error. Items are stored device-only and available when the device is unlocked.
    ///
    /// - Parameters:
    ///   - secret: The secret string to store.
    ///   - account: The namespaced account string (see `Account`).
    /// - Returns: true if the secret was saved or updated successfully.
    @discardableResult
    func save(_ secret: String, account: String) -> Bool {
        guard let data = secret.data(using: .utf8) else { return false }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            // Update existing item's data (and (re)assert accessibility).
            let attributesToUpdate: [CFString: Any] = [
                kSecValueData: data,
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            return SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary) == errSecSuccess
        } else if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData] = data
            newItem[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            return SecItemAdd(newItem as CFDictionary, nil) == errSecSuccess
        } else {
            return false
        }
    }

    /// Retrieves the secret stored under `account`, or nil if absent / access denied / decode fails.
    func secret(account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let secret = String(data: data, encoding: .utf8) else {
            return nil
        }
        return secret
    }

    /// Deletes the secret under `account`. Returns true if deleted or already absent.
    @discardableResult
    func delete(account: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Typed convenience (adversarial bot)

    /// Saves an adversarial-bot provider key for the given config ID.
    @discardableResult
    func saveAPIKey(for id: AdversarialTestConfig.ID, key: String) -> Bool {
        save(key, account: Account.adversarialBot(id))
    }

    /// Retrieves the adversarial-bot provider key for the given config ID.
    func apiKey(for id: AdversarialTestConfig.ID) -> String? {
        secret(account: Account.adversarialBot(id))
    }

    /// Deletes the adversarial-bot provider key for the given config ID.
    @discardableResult
    func deleteAPIKey(for id: AdversarialTestConfig.ID) -> Bool {
        delete(account: Account.adversarialBot(id))
    }
}
