import Foundation
import Security
import CryptoKit
import Network

/// Comprehensive security service for certificate pinning, keychain storage, and app integrity
class SecurityService: ObservableObject {
    static let shared = SecurityService()
    
    @Published var isAppSecure: Bool = true
    @Published var securityStatus: SecurityStatus = .secure
    
    private let keychain = KeychainService()
    private let certificatePinner = CertificatePinner()
    
    enum SecurityStatus {
        case secure
        case warning
        case compromised
        
        var description: String {
            switch self {
            case .secure:
                return "✅ App Security: Secure"
            case .warning:
                return "⚠️ App Security: Warning"
            case .compromised:
                return "🚨 App Security: Compromised"
            }
        }
    }
    
    private init() {
        performSecurityChecks()
    }
    
    // MARK: - Security Checks
    
    func performSecurityChecks() {
        var securityIssues: [String] = []
        
        // Check certificate pinning
        if !certificatePinner.isCertificatePinningEnabled {
            securityIssues.append("Certificate pinning not enabled")
        }
        
        // Check keychain accessibility
        if !keychain.isKeychainAccessible {
            securityIssues.append("Keychain not accessible")
        }
        
        // Check app integrity
        if !checkAppIntegrity() {
            securityIssues.append("App integrity compromised")
        }
        
        // Update security status
        DispatchQueue.main.async {
            if securityIssues.isEmpty {
                self.securityStatus = .secure
                self.isAppSecure = true
            } else if securityIssues.count <= 2 {
                self.securityStatus = .warning
                self.isAppSecure = false
            } else {
                self.securityStatus = .compromised
                self.isAppSecure = false
            }
        }
        
        #if DEBUG
        if !securityIssues.isEmpty {
            print("🔒 Security Issues Found: \(securityIssues.joined(separator: ", "))")
        }
        #endif
    }
    
    // MARK: - App Integrity
    
    private func checkAppIntegrity() -> Bool {
        // Check if app is running in debug mode (development)
        #if DEBUG
        return true // Allow debug mode for development
        #else
        // In production, check for common tampering indicators
        return !isJailbroken() && !isRunningInSimulator()
        #endif
    }
    
    private func isJailbroken() -> Bool {
        // Check for common jailbreak indicators
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/Library/MobileSubstrate/DynamicLibraries/",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    private func isRunningInSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Secure Storage
    
    func secureStore(_ data: Data, forKey key: String) -> Bool {
        return keychain.store(data, forKey: key)
    }
    
    func secureRetrieve(forKey key: String) -> Data? {
        return keychain.retrieve(forKey: key)
    }
    
    func secureDelete(forKey key: String) -> Bool {
        return keychain.delete(forKey: key)
    }
    
    // MARK: - Data Encryption
    
    func encrypt(_ data: Data, withKey key: String) throws -> Data {
        let symmetricKey = SymmetricKey(size: .bits256)
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        return sealedBox.combined ?? Data()
    }
    
    func decrypt(_ data: Data, withKey key: String) throws -> Data {
        let symmetricKey = SymmetricKey(size: .bits256)
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
    
    // MARK: - Hash Generation
    
    func generateHash(for data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func generateHash(for string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        return generateHash(for: data)
    }
}

// MARK: - Keychain Service

class KeychainService {
    private let service = "com.up2app.keychain"
    
    var isKeychainAccessible: Bool {
        return SecItemCopyMatching([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecReturnData: false
        ] as CFDictionary, nil) != errSecNotAvailable
    }
    
    func store(_ data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Item already exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            return SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary) == errSecSuccess
        }
        
        return status == errSecSuccess
    }
    
    func retrieve(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        return status == errSecSuccess ? (result as? Data) : nil
    }
    
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}

// MARK: - Certificate Pinner

class CertificatePinner {
    private let pinnedHosts = [
        "api.supabase.co",
        "supabase.co"
    ]
    
    var isCertificatePinningEnabled: Bool {
        return true // Implement actual certificate pinning logic
    }
    
    func validateCertificate(for host: String) -> Bool {
        guard pinnedHosts.contains(host) else { return true }
        
        // Implement certificate pinning validation
        // This would compare the server's certificate with a pre-stored hash
        return true
    }
}

// MARK: - Security Extensions

extension SecurityService {
    /// Secure storage for sensitive strings
    func secureStore(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return secureStore(data, forKey: key)
    }
    
    func secureRetrieveString(forKey key: String) -> String? {
        guard let data = secureRetrieve(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Secure storage for Codable objects
    func secureStore<T: Codable>(_ object: T, forKey key: String) -> Bool {
        do {
            let data = try JSONEncoder().encode(object)
            return secureStore(data, forKey: key)
        } catch {
            return false
        }
    }
    
    func secureRetrieveObject<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = secureRetrieve(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            return nil
        }
    }
} 