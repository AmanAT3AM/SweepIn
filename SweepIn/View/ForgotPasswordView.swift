//
//  ForgotPasswordView.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//


import SwiftUI

struct ForgotPasswordView: View {
    
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = ForgotPasswordViewModel()
    
    var body: some View {
        ZStack {
            Color.appBG
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        titleSection
                        emailSection
                        resetButton
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .alert(
            viewModel.showSuccessAlert ? "Reset Link Sent" : "Reset Failed",
            isPresented: Binding(
                get: { viewModel.showSuccessAlert || viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.showSuccessAlert = false
                        viewModel.errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK") {
                if viewModel.showSuccessAlert {
                    router.navigatToBack()
                } else {
                    viewModel.errorMessage = nil
                }
            }
        } message: {
            Text(viewModel.showSuccessAlert
                 ? "We've sent a password reset link to your email address."
                 : (viewModel.errorMessage ?? "Couldn't send the reset link."))
        }
    }
}

// MARK: - UI Components
private extension ForgotPasswordView {
    
    var headerSection: some View {
        HStack {
            Button {
                router.navigatToBack()
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Forgot Password")
                .font(CleanlyFont.sora(34, weight: .bold))
                .foregroundStyle(Color.ink)
            
            Text("Enter your email and we'll send you a reset link.")
                .font(CleanlyFont.jakarta(17))
                .foregroundStyle(Color.stone)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    var emailSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EMAIL")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
            
            TextField("enter your email here", text: $viewModel.email)
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
    
    var resetButton: some View {
        Button {
            Task {
                await viewModel.sendResetLink()
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Send Reset Link")
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
        .disabled(viewModel.isButtonDisabled)
        .opacity(viewModel.isButtonDisabled ? 0.7 : 1)
        .padding(.top, 12)
    }
}

// MARK: - Preview
#Preview {
    ForgotPasswordView()
        .environmentObject(Router())
}
