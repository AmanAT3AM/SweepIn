//
//  SignUpView.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//


import Combine
import SwiftUI

struct SignUpView: View {

    @EnvironmentObject private var navigationManager : Router
    @EnvironmentObject private var sessionManager: SessionManager
//    @StateObject private var authViewModel = AuthService()
    @StateObject private var viewModel = SignupViewModel()

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            VStack(spacing: 0) {
                headerSection
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        titleSection
                        roleSection
                        nameSection
                        emailSection
                        phoneSection
                        passwordSection
                        termsSection
                        createAccountButton
                        signInSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        
        //  error alert
        .alert("Sign Up Failed", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    
}

// MARK: - Components
private extension SignUpView {

    var headerSection: some View {
        HStack {
            Button {
                navigationManager.navigatToBack()
//                router.pop()
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(CleanlyFont.jakarta(16, weight: .medium))
                    .foregroundStyle(Color.sky)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadowSm()
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create Account")
                .font(CleanlyFont.sora(34, weight: .bold))
                .foregroundStyle(Color.ink)

            Text("Join thousands of happy households")
                .font(CleanlyFont.jakarta(17))
                .foregroundStyle(Color.stone)
        }
    }

    var roleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ROLE")
                .font(CleanlyFont.jakarta(14, weight: .bold))
                .foregroundStyle(Color.stone)

            Picker("Select Role", selection: $viewModel.selectedRole) {
                ForEach(UserRole.allCases) { role in
                    Text(role.rawValue).tag(role)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadowSm()
        }
    }

    var nameSection: some View {
        HStack(spacing: 16) {
            // First Name
            VStack(alignment: .leading, spacing: 10) {
                Text("FIRST NAME")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)

                TextField("Aman", text: $viewModel.firstName)
                    .font(.system(size: 18, weight: .medium))
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 20)
                    .frame(height: 60)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            // Last Name
            VStack(alignment: .leading, spacing: 10) {
                Text("LAST NAME")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)

                TextField("prajapati", text: $viewModel.lastName)
                    .font(.system(size: 18, weight: .medium))
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 20)
                    .frame(height: 60)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    var emailSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EMAIL")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)

            TextField("enter email here", text: $viewModel.email)
                .font(.system(size: 18, weight: .medium))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal, 20)
                .frame(height: 60)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    var phoneSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PHONE")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)

            TextField("+91 xxxxxxxxxxx", text: $viewModel.phone)
                .font(.system(size: 18, weight: .medium))
                .keyboardType(.phonePad)
                .padding(.horizontal, 20)
                .frame(height: 60)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    var passwordSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PASSWORD")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)

            HStack {
                Group {
                    if viewModel.isPasswordVisible {
                        TextField("Create password", text: $viewModel.password)
                    } else {
                        SecureField("Create password", text: $viewModel.password)
                    }
                }
                .font(.system(size: 18, weight: .medium))

                Button {
                    viewModel.isPasswordVisible.toggle()
                } label: {
                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 60)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    var termsSection: some View {
        Text("By signing up you agree to our Terms & Privacy Policy")
            .font(CleanlyFont.jakarta(14))
            .foregroundStyle(Color.stone)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }
    
    
    var createAccountButton: some View {
        Button {
            Task {
                await viewModel.createAccount()
                
                if !AuthService.shared.isError {
                    let destination = sessionManager.rootDestination
                    ?? (viewModel.selectedRole == .provider ? .providerTab : .mainTab)
                    navigationManager.navigateToNext(screenName: destination)
                }
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Create Account")
                        .font(CleanlyFont.jakarta(18, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(LinearGradient.splashBG)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadowBlue()
        }
        .disabled(viewModel.isSignupDisabled)
        .opacity(viewModel.isSignupDisabled ? 0.7 : 1)
    }

//    var createAccountButton: some View {
//        Button {
//            viewModel.createAccount {
////                navigationManager.navigateToNext(screenName: )
//            }
//        } label: {
//            Group {
//                if viewModel.isLoading {
//                    ProgressView()
//                        .tint(.white)
//                } else {
//                    Text("Create Account")
//                        .font(CleanlyFont.jakarta(18, weight: .bold))
//                }
//            }
//            .foregroundStyle(.white)
//            .frame(maxWidth: .infinity)
//            .frame(height: 60)
//            .background(LinearGradient.splashBG)
//            .clipShape(RoundedRectangle(cornerRadius: 20))
//            .shadowBlue()
//        }
//        .disabled(viewModel.isSignupDisabled)
//        .opacity(viewModel.isSignupDisabled ? 0.7 : 1)
//    }

    var signInSection: some View {
        HStack(spacing: 4) {
            Text("Already have an account?")
                .foregroundStyle(Color.stone)

            Button("Log-In") {
                navigationManager.navigateToNext(screenName: .Login)
//                router.pop()
            }
            .fontWeight(.bold)
            .foregroundStyle(Color.sky)
        }
        .font(CleanlyFont.jakarta(15))
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

#Preview {
    SignUpView()
        .environmentObject(Router())
        .environmentObject(SessionManager())
}
