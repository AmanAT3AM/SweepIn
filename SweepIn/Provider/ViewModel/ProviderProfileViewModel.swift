//
//  ProviderProfileViewModel.swift
//  SweepIn
//
//  Created by apple on 28/04/26.
//

import SwiftUI
import Combine

@MainActor
final class ProviderProfileViewModel: ObservableObject {

    @Published var userName = "Provider"
    @Published var email = "Not added"
    @Published var initials = "PR"

    @Published var stats: [ProfileStat] = [
        ProfileStat(title: "Jobs", value: "124"),
        ProfileStat(title: "Rating", value: "4.9"),
        ProfileStat(title: "Earnings", value: "₹24k")
    ]

    @Published var sections: [ProfileSection] = []

    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthService? = nil) {
        self.authService = authService ?? AuthService.shared
        bindUser()
    }

    func editProfile() { }

    func signOut() {
        authService.logout()
    }

    private func bindUser() {
        apply(user: authService.currentUser)

        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.apply(user: user)
            }
            .store(in: &cancellables)
    }

    private func apply(user: User?) {
        userName = user?.displayName ?? "Provider"
        email = user?.emailText ?? "Not added"
        initials = user?.initials ?? "PR"
        buildSections(user: user)
    }

    private func buildSections(user: User?) {
        sections = [
            ProfileSection(title: "ACCOUNT DETAILS", items: [
                ProfileMenuItem(title: "Full name", subtitle: user?.displayName ?? "Not available", icon: "person.text.rectangle", badge: nil, tint: .blue, action: nil),
                ProfileMenuItem(title: "Email", subtitle: user?.emailText ?? "Not available", icon: "envelope", badge: nil, tint: .blue, action: nil),
                ProfileMenuItem(title: "Phone", subtitle: user?.phoneText ?? "Not added", icon: "phone", badge: nil, tint: .blue, action: nil),
                ProfileMenuItem(title: "Role", subtitle: user?.roleTitle.isEmpty == false ? user?.roleTitle : UserRole.provider.rawValue, icon: "person.crop.circle.badge.checkmark", badge: nil, tint: .blue, action: nil)
            ]),
            ProfileSection(title: "MY SERVICES", items: [
                ProfileMenuItem(title: "Manage Services", icon: "briefcase", badge: nil, tint: .blue, action: nil),
                ProfileMenuItem(title: "Availability", icon: "calendar", badge: nil, tint: .blue, action: nil),
                ProfileMenuItem(title: "Earnings", icon: "indianrupeesign", badge: nil, tint: .green, action: nil)
            ]),
            ProfileSection(title: "SUPPORT", items: [
                ProfileMenuItem(title: "Notifications", icon: "bell", badge: 3, tint: .orange, action: nil),
                ProfileMenuItem(title: "Privacy", icon: "lock", badge: nil, tint: .blue, action: nil),
                ProfileMenuItem(title: "Help Center", icon: "questionmark.circle", badge: nil, tint: .blue, action: nil)
            ])
        ]
    }
}
