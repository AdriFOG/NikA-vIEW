import Foundation
import LocalAuthentication
import Security

/// Cómo quiere el usuario desbloquear Nikaido Vault.
/// - Primera vez: siempre contraseña.
/// - Después de entrar, la app pregunta una sola vez: Face ID o contraseña.
enum NikaidoUnlockMethod: String {
    case faceID
    case password
}

enum NikaidoBiometricLoadResult {
    case success(String)
    case cancelled
    case invalidated
    case failed(String)
}

enum NikaidoUnlockPreference {
    private static let methodKey = "NikaidoVault.unlockMethod.v1"
    private static let service = "com.teamnikaido.solidsecviewer.vault-unlock"
    private static let account = "vault-password"

    static var method: NikaidoUnlockMethod? {
        get {
            UserDefaults.standard
                .string(forKey: methodKey)
                .flatMap(NikaidoUnlockMethod.init(rawValue:))
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.rawValue, forKey: methodKey)
            } else {
                UserDefaults.standard.removeObject(forKey: methodKey)
            }
        }
    }

    static var biometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }

    /// Confirma Face ID una vez y guarda la contraseña en el Keychain,
    /// protegida por biometría de este iPhone (no se sincroniza a iCloud).
    static func enableBiometric(password: String) async -> Bool {
        guard biometricsAvailable else { return false }

        let confirmed: Bool = await withCheckedContinuation { continuation in
            let context = LAContext()
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Activar Face ID para Nikaido Vault"
            ) { success, _ in
                continuation.resume(returning: success)
            }
        }

        guard confirmed else { return false }

        return await Task.detached(priority: .userInitiated) {
            storePassword(password)
        }.value
    }

    static func disableBiometric() {
        deleteStoredPassword()
        method = nil
    }

    static func loadPassword(reason: String) async -> NikaidoBiometricLoadResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let context = LAContext()
                context.localizedReason = reason

                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                    kSecAttrAccount as String: account,
                    kSecReturnData as String: true,
                    kSecMatchLimit as String: kSecMatchLimitOne,
                    kSecUseAuthenticationContext as String: context
                ]

                var item: CFTypeRef?
                let status = SecItemCopyMatching(query as CFDictionary, &item)

                switch status {
                case errSecSuccess:
                    if
                        let data = item as? Data,
                        let text = String(data: data, encoding: .utf8),
                        !text.isEmpty
                    {
                        continuation.resume(returning: .success(text))
                    } else {
                        continuation.resume(returning: .invalidated)
                    }
                case errSecUserCanceled, errSecAuthFailed:
                    continuation.resume(returning: .cancelled)
                case errSecItemNotFound:
                    continuation.resume(returning: .invalidated)
                default:
                    continuation.resume(
                        returning: .failed("Face ID no respondió (código \(status)). Usa tu contraseña.")
                    )
                }
            }
        }
    }

    private static func storePassword(_ password: String) -> Bool {
        deleteStoredPassword()

        var accessError: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .biometryCurrentSet,
            &accessError
        ) else {
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessControl as String: access,
            kSecValueData as String: Data(password.utf8)
        ]

        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    private static func deleteStoredPassword() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}


// MARK: - Autenticación al abrir archivos de la bóveda

enum NikaidoFileAuthResult {
    case success
    case cancelled
    case needsPassword
}

/// Segunda barrera al abrir contenido de la bóveda: Face ID o, si no está
/// disponible, la contraseña de la bóveda. Nada se descifra para mostrarse
/// hasta que esta verificación tenga éxito.
enum NikaidoFileAuth {
    private static let requireKey = "NikaidoVault.requireFileAuth.v1"
    private static let graceKey = "NikaidoVault.fileAuthGraceSeconds.v1"
    private static var lastSuccess: Date?

    static var isRequired: Bool {
        UserDefaults.standard.object(forKey: requireKey) as? Bool ?? true
    }

    static var graceSeconds: Int {
        UserDefaults.standard.integer(forKey: graceKey)
    }

    static var isWithinGrace: Bool {
        guard graceSeconds > 0, let lastSuccess else { return false }
        return Date().timeIntervalSince(lastSuccess) < Double(graceSeconds)
    }

    static func markAuthenticated() {
        lastSuccess = Date()
    }

    static func reset() {
        lastSuccess = nil
    }

    static func authenticate(reason: String) async -> NikaidoFileAuthResult {
        guard
            NikaidoUnlockPreference.method == .faceID,
            NikaidoUnlockPreference.biometricsAvailable
        else {
            return .needsPassword
        }

        let context = LAContext()
        context.localizedFallbackTitle = "Usar contraseña"

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, error in
                if success {
                    continuation.resume(returning: .success)
                    return
                }

                let code = (error as? LAError)?.code

                switch code {
                case .userCancel, .systemCancel, .appCancel:
                    continuation.resume(returning: .cancelled)
                default:
                    continuation.resume(returning: .needsPassword)
                }
            }
        }
    }
}
