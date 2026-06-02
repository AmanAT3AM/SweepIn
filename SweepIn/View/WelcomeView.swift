//
//  WellcomeView.swift
//  SweepIn
//
//  Created by apple on 26/04/26.
//
import SwiftUI
import AuthenticationServices
import Combine
import UIKit

struct WellcomeView: View {

    @StateObject private var viewModel = WelcomeViewModel()
    @State private var presentingViewController: UIViewController?
    @EnvironmentObject var navigationManager: Router

    var body: some View {

            ZStack {
                backgroundView

                VStack(spacing: 0) {
                    Spacer()

                    logoSection

                    Spacer()

                    actionSection
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 40)
            }
            .background(
                ViewControllerResolver { viewController in
                    presentingViewController = viewController
                }
                .allowsHitTesting(false)
            )
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .alert("Sign In Failed", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .navigationDestination(isPresented: $viewModel.navigateToLogin) {
//                LoginView()
            }
            .navigationDestination(isPresented: $viewModel.navigateToSignUp) {
//                SignUpView()
            }

    }
}

//  - Components
private extension WellcomeView {

    var backgroundView: some View {
        ZStack {
            LinearGradient.splashBG
                .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 420, height: 420)
                .offset(x: 180, y: -260)

            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 260, height: 260)
                .offset(x: -180, y: 280)
        }
    }

    var logoSection: some View {
        VStack(spacing: 28) {
            appIcon

            badgeView

            titleSection
        }
    }

    var appIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }
                .frame(width: 120, height: 120)
                .shadowBlue()

            Image(systemName: "sparkles")
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    var badgeView: some View {
        Text("HOME SERVICES")
            .font(CleanlyFont.jakarta(14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            }
    }

    var titleSection: some View {
        VStack(spacing: 18) {
            Text("SweepIn")
                .font(CleanlyFont.sora(54, weight: .regular))
                .foregroundStyle(.white)

            Text("Professional home cleaning,\ntrusted by thousands across India.")
                .font(CleanlyFont.jakarta(18))
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 12)
        }
    }

    var actionSection: some View {
        VStack(spacing: 18) {
            loginButton

            signUpButton

            dividerView

            socialButtons

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            }
        }
    }

    var loginButton: some View {
        Button {
            navigationManager.navigateToNext(screenName: .Login)
//            viewModel.loginTapped()
        } label: {
            Text("Login to your account")
                .font(CleanlyFont.jakarta(19, weight: .bold))
                .foregroundStyle(Color.sky)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadowMd()
        }
    }

    var signUpButton: some View {
        Button {
            navigationManager.navigateToNext(screenName: .SignUp)
//            viewModel.signUpTapped()
        } label: {
            Text("Create a new account")
                .font(CleanlyFont.jakarta(19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                }
        }
    }

    var dividerView: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(height: 1)

            Text("or continue with")
                .font(CleanlyFont.jakarta(15))
                .foregroundStyle(.white.opacity(0.75))

            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }

    var socialButtons: some View {
        HStack(spacing: 16) {
            SocialButton(
                title: "Google",
                imageName: Image(.google),
                action: startGoogleSignIn
            )
            .disabled(viewModel.isLoading)
            .opacity(viewModel.isLoading ? 0.7 : 1)

            appleSignInButton
                .disabled(viewModel.isLoading)
                .opacity(viewModel.isLoading ? 0.7 : 1)
        }
    }

    var appleSignInButton: some View {
        SignInWithAppleButton(.continue) { request in
            viewModel.prepareAppleSignIn(request)
        } onCompletion: { result in
            Task {
                if let destination = await viewModel.handleAppleSignIn(result: result) {
                    navigationManager.replace(with: destination)
                }
            }
        }
        .signInWithAppleButtonStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
    }

    func startGoogleSignIn() {
        Task {
            guard let presentingViewController else {
                viewModel.errorMessage = "Couldn't start Google Sign-In."
                return
            }

            if let destination = await viewModel.signInWithGoogle(
                presentingViewController: presentingViewController
            ) {
                navigationManager.replace(with: destination)
            }
        }
    }
}

private struct ViewControllerResolver: UIViewControllerRepresentable {
    let onResolve: (UIViewController) -> Void

    func makeUIViewController(context: Context) -> ResolverViewController {
        ResolverViewController(onResolve: onResolve)
    }

    func updateUIViewController(_ uiViewController: ResolverViewController, context: Context) { }
}

private final class ResolverViewController: UIViewController {
    private let onResolve: (UIViewController) -> Void

    init(onResolve: @escaping (UIViewController) -> Void) {
        self.onResolve = onResolve
        super.init(nibName: nil, bundle: nil)
        view.isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onResolve(self)
    }
}

// Social Button
struct SocialButton: View {
    let title: String
    let imageName: Image
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                imageName
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(CleanlyFont.jakarta(18, weight: .medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(.white.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
        }
    }
}


#Preview {
    WellcomeView()
        .environmentObject(Router())
        
}
