import Foundation

#if canImport(Security)
import Security
#endif

public protocol SecureStore {
    @discardableResult
    func save(key: String, data: Data) -> Bool
    func load(key: String) -> Data?
    func delete(key: String)
}

public final class InMemorySecureStore: SecureStore {
    private var storage: [String: Data] = [:]

    public init() {}

    public func save(key: String, data: Data) -> Bool {
        storage[key] = data
        return true
    }

    public func load(key: String) -> Data? {
        storage[key]
    }

    public func delete(key: String) {
        storage.removeValue(forKey: key)
    }
}

public final class KeychainSecureStore: SecureStore {
    private let serviceName: String

    public init(serviceName: String = "com.childlock.secure") {
        self.serviceName = serviceName
    }

    @discardableResult
    public func save(key: String, data: Data) -> Bool {
        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            return true
        }

        guard status == errSecDuplicateItem else {
            return false
        }

        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        return SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary) == errSecSuccess
        #else
        return false
        #endif
    }

    public func load(key: String) -> Data? {
        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else {
            return nil
        }

        return result as? Data
        #else
        return nil
        #endif
    }

    public func delete(key: String) {
        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        #endif
    }
}
