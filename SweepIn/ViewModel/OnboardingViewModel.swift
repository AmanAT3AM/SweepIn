//
//  OnboardingViewModel.swift
//  SweepIn
//
//  Created by apple on 26/04/26.
//

import SwiftUI
import Combine


//  - Onboarding Step Model
struct OnboardingStep: Identifiable {
    let id: Int
    let stepLabel: String
    let title: String
    let highlight: String
    let description: String
    let cardGradient: LinearGradient
}

//  - ViewModel
final class OnboardingViewModel: ObservableObject {

    @Published var currentStep: Int = 0

    let steps: [OnboardingStep] = [
        OnboardingStep(
            id: 0,
            stepLabel: "STEP 1 OF 3",
            title: "Book your clean in  \n",
            highlight: "60 seconds",
            description: "Browse verified professionals near you and schedule a clean before your morning coffee is done.",
            cardGradient: LinearGradient(
                colors: [Color.sky5, Color.sky3],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        OnboardingStep(
            id: 1,
            stepLabel: "STEP 2 OF 3",
            title: "Trusted & verified\n",
            highlight: "professionals",
            description: "Every cleaner is background-checked, rated, and reviewed by thousands of happy customers.",
            cardGradient: LinearGradient(
                colors: [Color.mint2, Color.sky5],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        OnboardingStep(
            id: 2,
            stepLabel: "STEP 3 OF 3",
            title: "Relax, we've got\nyou ",
            highlight: "covered",
            description: "Sit back and enjoy your spotless home. We handle everything from scheduling to payment.",
            cardGradient: LinearGradient(
                colors: [Color.gold2, Color.sky5],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    ]

    var currentStepData: OnboardingStep {
        steps[currentStep]
    }

    var isLastStep: Bool {
        currentStep == steps.count - 1
    }
    // this var in first screen disable the skip button
    var isFirstStep: Bool {
        currentStep == 0
    }

    //  - Intent Actions
    func continueTapped() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep += 1
        }
    }

    func goToStep(_ index: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
            currentStep = index
        }
    }
}
