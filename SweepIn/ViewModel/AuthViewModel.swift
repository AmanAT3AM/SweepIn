//
//  AuthViewModel.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

//import Foundation
//import Combine
//
//class AuthViewModel: ObservableObject {
//    @Published var selectedRole: UserRole = .customer
//    @Published var firstName: String = ""
//    @Published var lastName: String = ""
//    @Published var email: String = ""
//    @Published var phone: String = ""
//    @Published var password: String = ""
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String?
//    @Published var currentUser: User?
//    @Published var isAuthenticated: Bool = false
//    @Published var onboardingStep: Int = 1
//    @Published var showOnboarding: Bool = true
// 
//    var isSignUpValid: Bool {
//        !firstName.isEmpty && !email.isEmpty && !phone.isEmpty && !password.isEmpty
//    }
// 
//    func signUp() {
//        guard isSignUpValid else {
//            errorMessage = "Please fill in all fields."
//            return
//        }
//        isLoading = true
//        // Simulate network call
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
//            let user = User(
//                firstName: self.firstName, lastName: self.lastName,
//                email: self.email, phone: self.phone,
//                role: self.selectedRole
//            )
//            self.currentUser = user
//            self.isAuthenticated = true
//            self.isLoading = false
//        }
//    }
// 
//    func signIn(email: String, password: String) {
//        isLoading = true
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            // Demo: load mock based on role selection
//            if self.selectedRole == .customer {
////                self.currentUser = .mockCustomer
//            } else {
//                self.currentUser = .mockProvider
//            }
//            self.isAuthenticated = true
//            self.isLoading = false
//        }
//    }
// 
//    func signOut() {
//        currentUser = nil
//        isAuthenticated = false
//        firstName = ""; lastName = ""; email = ""; phone = ""; password = ""
//        onboardingStep = 1; showOnboarding = true
//    }
// 
//    func nextOnboardingStep() {
//        if onboardingStep < 3 { onboardingStep += 1 }
//        else { showOnboarding = false }
//    }
// 
//    // Quick demo login
//    func demoLogin(as role: UserRole) {
//        selectedRole = role
////        currentUser = role == .customer ? .mockCustomer : .mockProvider
//        isAuthenticated = true
//    }
//}
