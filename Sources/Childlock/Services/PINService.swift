import CryptoKit
import Foundation

@MainActor
public final class PINService {
    public static let shared = PINService()

    private let keychainKey = "com.childlock.pin"
    private let secureStore: SecureStore
    private let sessionTimeout: TimeInterval
    private let now: () -> Date

    private var sessionUnlocked = false
    private var lastUnlockTime: Date?

    public init(
        secureStore: SecureStore = KeychainSecureStore(),
        sessionTimeout: TimeInterval = 300,
        now: @escaping () -> Date = Date.init
    ) {
        self.secureStore = secureStore
        self.sessionTimeout = sessionTimeout
        self.now = now
    }

    @discardableResult
    public func setPIN(_ pin: String) -> Bool {
        let salt = UUID().uuidString
        let hash = Self.hash(pin: pin, salt: salt)
        let payload = PINStorage(hash: hash, salt: salt)

        guard let data = try? JSONEncoder().encode(payload) else {
            return false
        }

        return secureStore.save(key: keychainKey, data: data)
    }

    public func verify(_ pin: String) -> Bool {
        guard
            let data = secureStore.load(key: keychainKey),
            let payload = try? JSONDecoder().decode(PINStorage.self, from: data)
        else {
            return false
        }

        let computedHash = Self.hash(pin: pin, salt: payload.salt)
        let matches = computedHash == payload.hash

        if matches {
            sessionUnlocked = true
            lastUnlockTime = now()
        }

        return matches
    }

    public var isSessionUnlocked: Bool {
        guard sessionUnlocked, let lastUnlockTime else {
            return false
        }

        return now().timeIntervalSince(lastUnlockTime) < sessionTimeout
    }

    public func lockSession() {
        sessionUnlocked = false
        lastUnlockTime = nil
    }

    private static func hash(pin: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((pin + salt).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private struct PINStorage: Codable {
    let hash: String
    let salt: String
}
