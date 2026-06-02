//
//  ProfileViewModel.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

import Combine
import Foundation
import SwiftUI
import FirebaseDatabase

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var userName = "Customer"
    @Published var email = "Not added"
    @Published var initials = "CU"

    @Published var stats: [ProfileStat] = [
        .init(title: "Bookings", value: "0"),
        .init(title: "Spent", value: "₹0"),
        .init(title: "Favourites", value: "1")
    ]

    @Published var sections: [ProfileSection] = []
    @Published var latestBooking: ServiceBooking?
    @Published var latestNotification: BookingNotificationItem?
    @Published var unreadNotificationCount: Int = 0

    private let authService: AuthService
    private let bookingService: BookingServicing
    private let db = Database.database().reference()
    private var cancellables = Set<AnyCancellable>()
    private var bookingsObservation: DatabaseObservationToken?
    private var notificationsObservation: DatabaseObservationToken?

    init(
        authService: AuthService? = nil,
        bookingService: BookingServicing = FirebaseBookingService.shared
    ) {
        self.authService = authService ?? AuthService.shared
        self.bookingService = bookingService
        bindUser()
    }

    func editProfile() {
        print("Edit Profile")
    }

    func signOut() {
        authService.logout()
    }

    deinit {
        bookingsObservation?.cancel()
        notificationsObservation?.cancel()
    }

    private func bindUser() {
        apply(user: authService.currentUser)

        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.apply(user: user)
                self?.startObserving(for: user)
                Task { [weak self] in
                    await self?.loadStats(for: user?.uid)
                }
            }
            .store(in: &cancellables)

        startObserving(for: authService.currentUser)
    }

    private func apply(user: User?) {
        userName = user?.displayName ?? "Customer"
        email = user?.emailText ?? "Not added"
        initials = user?.initials ?? "CU"
        buildSections(user: user)
        Task {
            await loadStats(for: user?.uid)
        }
    }

    private func startObserving(for user: User?) {
        bookingsObservation?.cancel()
        notificationsObservation?.cancel()
        latestBooking = nil
        latestNotification = nil
        unreadNotificationCount = 0

        guard let customerID = user?.uid else { return }

        bookingsObservation = bookingService.observeCustomerBookings(customerId: customerID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let bookings):
                self.latestBooking = bookings.first(where: { $0.status == .upcoming && !$0.isExpiredAwaitingProviderResponse })
                    ?? bookings.first(where: { $0.status == .completed || $0.status == .cancelled })
            case .failure:
                self.latestBooking = nil
            }
        }

        notificationsObservation = bookingService.observeNotifications(userId: customerID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let notifications):
                self.latestNotification = notifications.first
                self.unreadNotificationCount = notifications.filter { !$0.isRead }.count
            case .failure:
                self.latestNotification = nil
                self.unreadNotificationCount = 0
            }
        }
    }

    private func buildSections(user: User?) {
        sections = [
            .init(
                title: "ACCOUNT DETAILS",
                items: [
                    .init(title: "Full name", subtitle: user?.displayName ?? "Not available", icon: "person.text.rectangle", badge: nil, tint: .blue, action: nil),
                    .init(title: "Email", subtitle: user?.emailText ?? "Not available", icon: "envelope", badge: nil, tint: .blue, action: nil),
                    .init(title: "Phone", subtitle: user?.phoneText ?? "Not added", icon: "phone", badge: nil, tint: .blue, action: nil),
                    .init(title: "Role", subtitle: user?.roleTitle.isEmpty == false ? user?.roleTitle : UserRole.customer.rawValue, icon: "person.crop.circle.badge.checkmark", badge: nil, tint: .blue, action: nil)
                ]
            ),
            .init(
                title: "PREFERENCES",
                items: [
                    .init(title: "Favourite cleaners", icon: "star", badge: nil, tint: .blue, action: nil),
                    .init(title: "Notifications", icon: "clock", badge: 3, tint: .blue, action: nil)
                ]
            ),
            .init(
                title: "SUPPORT",
                items: [
                    .init(title: "Help & support", icon: "message", badge: nil, tint: .blue, action: nil)
                ]
            )
        ]
    }

    private func loadStats(for uid: String?) async {
        guard let uid else {
            stats = [
                .init(title: "Bookings", value: "0"),
                .init(title: "Spent", value: "₹0"),
                .init(title: "Favourites", value: "1")
            ]
            return
        }

        do {
            let snapshot = try await db.child("users").child(uid).child("stats").getData()
            let values = snapshot.value as? [String: Any] ?? [:]

            let bookingCount = number(from: values["bookingCount"])
            let totalSpent = number(from: values["totalSpent"])

            stats = [
                .init(title: "Bookings", value: "\(bookingCount)"),
                .init(title: "Spent", value: "₹\(totalSpent)"),
                .init(title: "Favourites", value: "1")
            ]
        } catch {
            stats = [
                .init(title: "Bookings", value: "0"),
                .init(title: "Spent", value: "₹0"),
                .init(title: "Favourites", value: "1")
            ]
        }
    }

    private func number(from value: Any?) -> Int {
        switch value {
        case let int as Int:
            return int
        case let number as NSNumber:
            return number.intValue
        case let string as String:
            return Int(string) ?? 0
        default:
            return 0
        }
    }
}
