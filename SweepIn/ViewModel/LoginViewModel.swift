//
//  LoginViewModel.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var email = ""
    @Published var password = ""
    @Published var isPasswordVisible = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    var isLoginDisabled: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        password.isEmpty ||
        isLoading
    }

    func login() async -> Router.Destination? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let destination = await AuthService.shared.login(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )

        if destination == nil {
            errorMessage = AuthService.shared.errorMessage ?? "Login failed. Please try again."
        }

        return destination
    }
}
