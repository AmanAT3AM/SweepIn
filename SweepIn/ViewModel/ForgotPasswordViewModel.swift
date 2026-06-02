//
//  ForgotPasswordViewModel.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

import SwiftUI
import Combine

// - ViewModel
@MainActor
final class ForgotPasswordViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var showSuccessAlert: Bool = false
    @Published var errorMessage: String?
    
    var isButtonDisabled: Bool {
        email.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
    }
    
    func sendResetLink() async {
        guard !isButtonDisabled else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let success = await AuthService.shared.sendPasswordReset(
            to: email.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if success {
            showSuccessAlert = true
        } else {
            errorMessage = AuthService.shared.errorMessage ?? "Couldn't send the password reset link."
        }
    }
}
