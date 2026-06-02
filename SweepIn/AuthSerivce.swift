//
//  AuthSerivce.swift
//  SweepIn
//
//  Created by apple on 28/04/26.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import Combine

@MainActor
final class AuthService: ObservableObject {

    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isError = false
    @Published var errorMessage: String?

    static let shared = AuthService()

    private let auth = Auth.auth()
    private let db = Database.database().reference()

    init() { }

    func loadCurrentUser() async {
        guard let user = auth.currentUser else {
            userSession = nil
            currentUser = nil
            return
        }

        userSession = user
        _ = await fetchUser(by: user.uid)
    }

    func login(email: String, password: String) async -> Router.Destination? {
        clearError()

        do {
            let authResult = try await auth.signIn(withEmail: email, password: password)
            userSession = authResult.user

            guard let user = await fetchUser(by: authResult.user.uid) else {
                isError = true
                errorMessage = "We couldn't load your account details. Please try again."
                return nil
            }

            guard let role = user.role else {
                isError = true
                errorMessage = "Your account role is missing or invalid."
                return nil
            }

            return destination(for: role)
        } catch {
            isError = true
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func loginWithGoogle(idToken: String, accessToken: String, fullName: String?, email: String?) async -> Router.Destination? {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        return await loginWithSocialCredential(
            credential,
            fallbackFullName: fullName,
            fallbackEmail: email
        )
    }

    func loginWithApple(idTokenString: String, nonce: String, fullName: String?, email: String?) async -> Router.Destination? {
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idTokenString,
            rawNonce: nonce
        )

        return await loginWithSocialCredential(
            credential,
            fallbackFullName: fullName,
            fallbackEmail: email
        )
    }

    func createUser(email: String, fullName: String, password: String, userRole: String, phone: String) async {
        clearError()

        do {
            let authResult = try await auth.createUser(withEmail: email, password: password)
            userSession = authResult.user

            try await storeUserInRealtimeDB(
                uid: authResult.user.uid,
                email: email,
                fullName: fullName,
                userRole: userRole,
                phone: phone)
            currentUser = await fetchUser(by: authResult.user.uid)
        } catch {
            isError = true
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        do {
            try auth.signOut()
            userSession = nil
            currentUser = nil
            clearError()
        } catch {
            isError = true
            errorMessage = error.localizedDescription
        }
    }

    func sendPasswordReset(to email: String) async -> Bool {
        clearError()

        do {
            try await auth.sendPasswordReset(withEmail: email)
            return true
        } catch {
            isError = true
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func fetchUser(by uid: String) async -> User? {
        do {
            let snapshot = try await db.child("users").child(uid).getData()

            guard let value = snapshot.value as? [String: Any] else {
                currentUser = nil
                return nil
            }

            let firstName = (value["firstName"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let lastName = (value["lastName"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let legacyFullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
            let fullName = (value["fullName"] as? String ?? legacyFullName).trimmingCharacters(in: .whitespacesAndNewlines)
            let storedRole = (value["userRole"] as? String ?? value["role"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            let user = User(
                uid: value["uid"] as? String ?? uid,
                email: value["email"] as? String ?? "",
                fullName: fullName,
                userRole: storedRole,
                phone: value["phone"] as? String ?? ""
            )

            currentUser = user
            return user
        } catch {
            return nil
        }
    }

    private func storeUserInRealtimeDB(uid: String, email: String, fullName: String, userRole: String, phone: String) async throws {
        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "fullName": fullName,
            "userRole": userRole,
            "phone": phone
        ]

        try await db.child("users").child(uid).setValue(userData)
    }

    private func destination(for role: UserRole) -> Router.Destination {
        switch role {
        case .customer:
            return .mainTab
        case .provider:
            return .providerTab
        }
    }

    private func clearError() {
        isError = false
        errorMessage = nil
    }

    private func loginWithSocialCredential(
        _ credential: AuthCredential,
        fallbackFullName: String?,
        fallbackEmail: String?,
        defaultRole: UserRole = .customer
    ) async -> Router.Destination? {
        clearError()

        do {
            let authResult = try await auth.signIn(with: credential)
            userSession = authResult.user

            guard let user = await ensureUserProfile(
                for: authResult.user,
                fallbackFullName: fallbackFullName,
                fallbackEmail: fallbackEmail,
                defaultRole: defaultRole
            ) else {
                if !isError {
                    isError = true
                    errorMessage = "We couldn't load your account details. Please try again."
                }
                return nil
            }

            guard let role = user.role else {
                isError = true
                errorMessage = "Your account role is missing or invalid."
                return nil
            }

            return destination(for: role)
        } catch {
            isError = true
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func ensureUserProfile(
        for firebaseUser: FirebaseAuth.User,
        fallbackFullName: String?,
        fallbackEmail: String?,
        defaultRole: UserRole
    ) async -> User? {
        let userRef = db.child("users").child(firebaseUser.uid)

        do {
            let snapshot = try await userRef.getData()
            var userData = snapshot.value as? [String: Any] ?? [:]
            var shouldWrite = snapshot.value == nil

            let existingEmail = normalizedString(from: userData["email"] as? String)
            let authEmail = normalizedString(from: firebaseUser.email)
            let fallbackEmailValue = normalizedString(from: fallbackEmail)
            let resolvedEmail = firstNonEmpty(existingEmail, authEmail, fallbackEmailValue)

            let existingFullName = normalizedString(from: userData["fullName"] as? String)
            let authDisplayName = normalizedString(from: firebaseUser.displayName)
            let fallbackFullNameValue = normalizedString(from: fallbackFullName)
            let legacyFirstName = normalizedString(from: userData["firstName"] as? String)
            let legacyLastName = normalizedString(from: userData["lastName"] as? String)
            let legacyFullName = "\(legacyFirstName) \(legacyLastName)"
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let fallbackNameFromEmail = displayNameFallback(from: resolvedEmail)
            let resolvedFullName = firstNonEmpty(
                existingFullName,
                fallbackFullNameValue,
                authDisplayName,
                legacyFullName,
                fallbackNameFromEmail
            )

            let existingRole = normalizedString(from: userData["userRole"] as? String)
            let legacyRole = normalizedString(from: userData["role"] as? String)
            let resolvedRole = firstNonEmpty(existingRole, legacyRole, defaultRole.rawValue)

            if normalizedString(from: userData["uid"] as? String).isEmpty {
                userData["uid"] = firebaseUser.uid
                shouldWrite = true
            }

            if existingEmail.isEmpty && !resolvedEmail.isEmpty {
                userData["email"] = resolvedEmail
                shouldWrite = true
            }

            if existingFullName.isEmpty && !resolvedFullName.isEmpty {
                userData["fullName"] = resolvedFullName
                shouldWrite = true
            }

            if existingRole.isEmpty && !resolvedRole.isEmpty {
                userData["userRole"] = resolvedRole
                shouldWrite = true
            }

            if userData["phone"] == nil {
                userData["phone"] = ""
                shouldWrite = true
            }

            if shouldWrite {
                try await userRef.setValue(userData)
            }

            return await fetchUser(by: firebaseUser.uid)
        } catch {
            isError = true
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func normalizedString(from value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func firstNonEmpty(_ values: String...) -> String {
        values.first(where: { !$0.isEmpty }) ?? ""
    }

    private func displayNameFallback(from email: String) -> String {
        guard !email.isEmpty else { return "" }

        return email
            .split(separator: "@")
            .first
            .map(String.init)?
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized ?? ""
    }
}
