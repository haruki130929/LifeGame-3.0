import Foundation
import AuthenticationServices

final class AppleSignInManager: ObservableObject {

    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var userName: String?
    @Published private(set) var userEmail: String?

    private enum Keys {
        static let userID = "apple.signIn.userID"
        static let userName = "apple.signIn.userName"
        static let userEmail = "apple.signIn.userEmail"
    }

    init() {
        loadFromKeychain()
        if isSignedIn {
            verifyCredentialState()
        }
    }

    // MARK: - Handle Sign In Result

    func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }

            let userID = credential.user
            KeychainHelper.save(userID, forKey: Keys.userID)

            // Apple 只在首次登入時提供姓名和 email
            if let fullName = credential.fullName {
                let name = [fullName.familyName, fullName.givenName]
                    .compactMap { $0 }
                    .joined(separator: "")
                if !name.isEmpty {
                    KeychainHelper.save(name, forKey: Keys.userName)
                    userName = name
                }
            }

            if let email = credential.email {
                KeychainHelper.save(email, forKey: Keys.userEmail)
                userEmail = email
            }

            isSignedIn = true
            debugLog("✅ Apple Sign In 成功：\(userID)")

        case .failure(let error):
            debugLog("❌ Apple Sign In 失敗：\(error.localizedDescription)")
        }
    }

    // MARK: - Sign Out

    func signOut() {
        KeychainHelper.remove(forKey: Keys.userID)
        KeychainHelper.remove(forKey: Keys.userName)
        KeychainHelper.remove(forKey: Keys.userEmail)
        isSignedIn = false
        userName = nil
        userEmail = nil
    }

    // MARK: - Verify (check if credential is still valid)

    func verifyCredentialState() {
        guard let userID = KeychainHelper.load(forKey: Keys.userID) else {
            isSignedIn = false
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { [weak self] state, _ in
            Task { @MainActor in
                switch state {
                case .authorized:
                    self?.isSignedIn = true
                case .revoked, .notFound:
                    self?.signOut()
                default:
                    break
                }
            }
        }
    }

    // MARK: - Keychain Persistence

    private func loadFromKeychain() {
        if let _ = KeychainHelper.load(forKey: Keys.userID) {
            isSignedIn = true
            userName = KeychainHelper.load(forKey: Keys.userName)
            userEmail = KeychainHelper.load(forKey: Keys.userEmail)
        }
    }

    /// 顯示用的帳號名稱
    var displayName: String {
        if let name = userName, !name.isEmpty { return name }
        if let email = userEmail, !email.isEmpty { return email }
        return "Apple ID 使用者"
    }
}
