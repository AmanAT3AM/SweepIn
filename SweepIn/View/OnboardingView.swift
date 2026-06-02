//
//  OnboardingView.swift
//  SweepIn
//
//  Created by apple on 26/04/26.
//

import SwiftUI

// - Onboarding Root View
struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var navigationManager: Router

    var body: some View {
        ZStack {
            Color.appBG
                .ignoresSafeArea()

            VStack(spacing: 0) {

                //  Top Bar
                HStack {
                    Spacer()
                    
                    if !viewModel.isFirstStep {
                        Button {
                            navigationManager.navigateToNext(screenName: .Wellcome)
                        } label: {
                            Text("Skip")
                                .font(CleanlyFont.jakarta(15, weight: .semibold))
                                .foregroundColor(.stone)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.fog2)
                                )
                        }
                        .padding(.trailing, 24)
                        .padding(.top, 14)
                    }
                }
                

                Spacer()
                    .frame(height: 20)

                // MARK: Illustration Pager
                TabView(selection: $viewModel.currentStep) {
                    ForEach(viewModel.steps) { step in
                        OnboardingIllustrationView(
                            step: step.id,
                            cardGradient: step.cardGradient
                        )
                        .tag(step.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 316)
                .animation(.easeInOut, value: viewModel.currentStep)

                Spacer()
                    .frame(height: 36)

                //  Text Content
                VStack(alignment: .leading, spacing: 10) {

                    Text(viewModel.currentStepData.stepLabel)
                        .font(CleanlyFont.jakarta(12, weight: .bold))
                        .foregroundColor(.sky)
                        .tracking(1.4)

                    (
                        Text(viewModel.currentStepData.title)
                            .foregroundColor(.ink)
                        +
                        Text(viewModel.currentStepData.highlight)
                            .foregroundColor(.sky)
                    )
                    .font(CleanlyFont.sora(30, weight: .bold))
                    .lineSpacing(3)
                    .id("title_\(viewModel.currentStep)")
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
                    .animation(.easeInOut(duration: 0.32),
                               value: viewModel.currentStep)

                    Text(viewModel.currentStepData.description)
                        .font(CleanlyFont.jakarta(15, weight: .regular))
                        .foregroundColor(.stone)
                        .lineSpacing(5)
                        .id("desc_\(viewModel.currentStep)")
                        .transition(.opacity)
                        .animation(
                            .easeInOut(duration: 0.28).delay(0.08),
                            value: viewModel.currentStep
                        )
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                //  Page Indicator
                HStack(spacing: 7) {
                    ForEach(0..<viewModel.steps.count, id: \.self) { index in
                        Capsule()
                            .fill(
                                index == viewModel.currentStep
                                ? Color.sky
                                : Color.fog
                            )
                            .frame(
                                width: index == viewModel.currentStep ? 28 : 8,
                                height: 8
                            )
                            .onTapGesture {
                                viewModel.goToStep(index)
                            }
                            .animation(
                                .spring(response: 0.38,
                                        dampingFraction: 0.7),
                                value: viewModel.currentStep
                            )
                    }

                    Spacer()
                }
                .padding(.horizontal, 28)

                Spacer()
                    .frame(height: 24)

                //  Continue Button
                Button {
                    if viewModel.isLastStep {
                        navigationManager.navigateToNext(screenName: .Wellcome)
                    } else {
                        viewModel.continueTapped()
                    }
                } label: {
                    Text(viewModel.isLastStep ? "Get Started" : "Continue")
                        .font(CleanlyFont.jakarta(17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(LinearGradient.splashBG)
                        )
                        .shadowBlue()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 38)
                .buttonStyle(OnboardingButtonStyle())
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

// - Button Style
struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.14),
                       value: configuration.isPressed)
    }
}

// - Illustration Container
struct OnboardingIllustrationView: View {
    let step: Int
    let cardGradient: LinearGradient

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28)
                .fill(cardGradient)

            Text(String(format: "%02d", step + 1))
                .font(CleanlyFont.sora(110, weight: .black))
                .foregroundColor(Color.fog.opacity(0.35))
                .padding(.leading, 18)
                .padding(.top, 8)
//                .lineSpacing(3)

            Group {
                switch step {
                case 0:
                    BookingIllustration()
                case 1:
                    VerifiedIllustration()
                case 2:
                    RelaxIllustration()
                default:
                    BookingIllustration()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 290)
        .padding(.horizontal, 24)
        .shadowMd()
    }
}

// MARK: - Step 1
struct BookingIllustration: View {
    var body: some View {
        Image(.onboard1)
            .resizable()
            .scaledToFill()
            .frame(width: 300, height: 350)
            .offset(y: 20)
    }
}

//  - Step 2
struct VerifiedIllustration: View {
    var body: some View {
        Image(.onboard2)
            .resizable()
            .scaledToFill()
            .frame(width: 300, height: 350)
            .offset(y: 20)
    }
}

//  - Step 3
struct RelaxIllustration: View {
    var body: some View {
        Image(.onboard3)
            .resizable()
            .scaledToFill()
            .frame(width: 300, height: 350)
            .offset(y: 20)
    }
}

// - Preview
#Preview {
    OnboardingView()
        .environmentObject(Router())
}
