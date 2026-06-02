//
//  LoginView.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//


import Combine
import SwiftUI

struct LoginView: View {

    @EnvironmentObject private var navigationManager : Router
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        ZStack {
            Color.appBG
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        titleSection
                        emailSection
                        passwordSection
                        forgotPasswordSection
                        loginButton
                        signupSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .alert("Login Failed", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

//  - Components
private extension LoginView {

    var headerView: some View {
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
            Text("Welcome Back")
                .font(CleanlyFont.sora(34, weight: .bold))
                .foregroundStyle(Color.ink)

            Text("Login to your SweepIn account")
                .font(CleanlyFont.jakarta(17))
                .foregroundStyle(Color.stone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var emailSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EMAIL")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)

            TextField("Enter your email here", text: $viewModel.email)
                .font(.system(size: 18, weight: .medium))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textContentType(.emailAddress)
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
                        TextField("Enter password", text: $viewModel.password)
                    } else {
                        SecureField("Enter password", text: $viewModel.password)
                    }
                }
                .font(.system(size: 18, weight: .medium))
                .textContentType(.password)

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

    var forgotPasswordSection: some View {
        HStack {
            Spacer()
            Button("Forgot Password?") {
                navigationManager.navigateToNext(screenName: .ForgotPassword)
//                router.push(.forgotPassword)
            }
            .font(CleanlyFont.jakarta(15, weight: .semibold))
            .foregroundStyle(Color.sky)
        }
    }
    
    var loginButton: some View {
        Button {
            Task {
                if let destination = await viewModel.login() {
                    navigationManager.replace(with: destination)
                }
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Login")
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
        .disabled(viewModel.isLoginDisabled)
        .opacity(viewModel.isLoginDisabled ? 0.7 : 1)
    }

    var signupSection: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .foregroundStyle(Color.stone)

            Button("Sign Up") {
                navigationManager.navigateToNext(screenName: .SignUp)
//                router.push(.signup)
            }
            .fontWeight(.bold)
            .foregroundStyle(Color.sky)
        }
        .font(CleanlyFont.jakarta(15))
        .padding(.top, 8)
    }
}

#Preview {
    LoginView()
        .environmentObject(Router())
        .environmentObject(SessionManager())
}
