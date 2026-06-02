//
//  SplashView.swift
//  SweepIn
//
//  Created by apple on 25/04/26.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var navigationManager: Router
    @EnvironmentObject var sessionManager: SessionManager
    @State private var isVisible = false
    @State private var didNavigate = false
    
    var body: some View {
        NavigationStack(path:$navigationManager.path){

                VStack(spacing:5) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                    //                .frame(width: 900, height:100)
                        .opacity(isVisible ? 1 : 0)
                    
//                    Text("Welcome To \n SweepIn")
//                        .multilineTextAlignment(.center)
//                        .foregroundStyle(.blue)
//                        .font(.system(size: 30, weight: .regular, design: .default))
//                        .opacity(isVisible ? 2/3 : 0)
                }
                .navigationBarHidden(true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        isVisible = true
                    }
                }
                .task {
                    await handleLaunch()
                }
            .navigationDestination(for: Router.Destination.self) { screenName in switch screenName {
                case .Onboarding:      OnboardingView()
                 case .Wellcome:       WellcomeView()
                 case .Login:           LoginView()
                 case .SignUp:          SignUpView()
                case .ForgotPassword:  ForgotPasswordView()
               case .mainTab:       MainTabView()
               case .providerTab:     ProviderTabView()
            }
            }
            .environmentObject(navigationManager)
            
        }
        .navigationBarHidden(true)
    }

    @MainActor
    private func handleLaunch() async {
        guard !didNavigate else { return }
        didNavigate = true

        await sessionManager.restoreSession()

        try? await Task.sleep(nanoseconds: 2_000_000_000)

        let destination = sessionManager.isLoggedIn
            ? sessionManager.launchDestination
            : .Onboarding

        navigationManager.replace(with: destination)
    }

}
#Preview {
    SplashView()
        .environmentObject(Router())
        .environmentObject(SessionManager())
}
