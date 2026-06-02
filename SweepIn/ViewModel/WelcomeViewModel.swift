//
//  WelcomeViewModel.swift
//  SweepIn
//
//  Created by apple on 26/04/26.
//

import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import CryptoKit
import FirebaseCore
import GoogleSignIn
import Security
import UIKit

@MainActor
final class WelcomeViewModel: ObservableObject {
    @Published var navigateToLogin = false
    @Published var navigateToSignUp = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var currentNonce: String?

    func loginTapped() {
        navigateToLogin = true
    }

    func signUpTapped() {
        navigateToSignUp = true
    }

    func signInWithGoogle(presentingViewController: UIViewController) async -> Router.Destination? {
        errorMessage = nil

        guard let clientID = resolvedGoogleClientID() else {
            errorMessage = "Google Sign-In is not configured. Download the latest iOS GoogleService-Info.plist so it includes CLIENT_ID and REVERSED_CLIENT_ID."
            return nil
        }

        isLoading = true
        defer { isLoading = false }

        do {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Couldn't get a Google identity token."
                return nil
            }

            let destination = await AuthService.shared.loginWithGoogle(
                idToken: idToken,
                accessToken: result.user.accessToken.tokenString,
                fullName: result.user.profile?.name,
                email: result.user.profile?.email
            )

            if destination == nil {
                errorMessage = AuthService.shared.errorMessage ?? "Google sign-in failed."
            }

            return destination
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func prepareAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async -> Router.Destination? {
        switch result {
        case .failure(let error):
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                return nil
            }

            errorMessage = error.localizedDescription
            return nil

        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Couldn't read the Apple account response."
                return nil
            }

            guard let nonce = currentNonce else {
                errorMessage = "Invalid Apple Sign-In state."
                return nil
            }

            guard let appleIDToken = appleIDCredential.identityToken else {
                errorMessage = "Couldn't create an Apple identity token."
                return nil
            }

            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Couldn't decode the Apple identity token."
                return nil
            }

            isLoading = true
            defer {
                isLoading = false
                currentNonce = nil
            }

            let destination = await AuthService.shared.loginWithApple(
                idTokenString: idTokenString,
                nonce: nonce,
                fullName: formattedFullName(from: appleIDCredential.fullName),
                email: appleIDCredential.email
            )

            if destination == nil {
                errorMessage = AuthService.shared.errorMessage ?? "Apple sign-in failed."
            }

            return destination
        }
    }

    private func formattedFullName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }

        let formattedName = PersonNameComponentsFormatter()
            .string(from: components)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return formattedName.isEmpty ? nil : formattedName
    }

    private func resolvedGoogleClientID() -> String? {
        if let firebaseClientID = FirebaseApp.app()?.options.clientID?.trimmingCharacters(in: .whitespacesAndNewlines),
           !firebaseClientID.isEmpty {
            return firebaseClientID
        }

        if let bundledClientID = Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as? String,
           !bundledClientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return bundledClientID
        }

        guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plistData = NSDictionary(contentsOfFile: plistPath) as? [String: Any],
              let clientID = plistData["CLIENT_ID"] as? String else {
            return nil
        }

        let trimmedClientID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedClientID.isEmpty ? nil : trimmedClientID
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randomBytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)

            if status != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with status \(status)")
            }

            randomBytes.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}
