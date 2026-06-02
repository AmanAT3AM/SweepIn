//
//  SignUpViewModel.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

import SwiftUI
import Combine

@MainActor
final class SignupViewModel: ObservableObject {
    
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var password = ""
    @Published var selectedRole: UserRole = .customer
    @Published var isPasswordVisible = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var isSignupDisabled: Bool {
        firstName.trimmingCharacters(in: .whitespaces).isEmpty ||
        lastName.trimmingCharacters(in: .whitespaces).isEmpty ||
        email.trimmingCharacters(in: .whitespaces).isEmpty ||
        phone.trimmingCharacters(in: .whitespaces).isEmpty ||
        password.count < 6 || // < 6 hona chahiye, > 6 nahi
        isLoading
    }
    
    
    func createAccount() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        //  firstName + lastName combine karke bhej rahe hain
        let fullName = "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))"
        
        await AuthService.shared.createUser(
            email: email.trimmingCharacters(in: .whitespaces),
            fullName: fullName,
            password: password,
            userRole: selectedRole.rawValue,
            phone: phone.trimmingCharacters(in: .whitespaces)
        )
        
        if AuthService.shared.isError {
            errorMessage = "Account creation failed. Please try again."
        }
    }
}
