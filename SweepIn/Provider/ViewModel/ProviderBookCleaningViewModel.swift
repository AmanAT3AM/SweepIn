//
//  ProviderBookCleaningViewModel.swift
//  SweepIn
//
//  Created by apple on 28/04/26.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

@MainActor
final class ProviderBookingViewModel: ObservableObject {

    @Published var selectedTab: ProviderBookingTab = .new
    @Published var bookings: [ServiceBooking] = []
    @Published var bannerMessage: String?
    @Published var unreadNotificationCount = 0
    @Published var isLoadingBookings = false
    @Published var errorMessage: String?
    @Published var processingBookingId: String?

    private let authService: AuthService
    private let bookingService: BookingServicing
    private var cancellables = Set<AnyCancellable>()
    private var bookingsObservation: DatabaseObservationToken?
    private var notificationsObservation: DatabaseObservationToken?
    private var seenNotificationIDs = Set<String>()
    private var observedProviderID: String?
    private var expiredBookingCleanupIDs = Set<String>()

    init(
        authService: AuthService? = nil,
        bookingService: BookingServicing = FirebaseBookingService.shared
    ) {
        self.authService = authService ?? AuthService.shared
        self.bookingService = bookingService
        bindUser()
    }

    deinit {
        bookingsObservation?.cancel()
        notificationsObservation?.cancel()
    }

    var filteredBookings: [ServiceBooking] {
        guard let providerID = authService.currentUser?.uid else { return [] }

        switch selectedTab {
        case .new:
            return bookings.filter {
                $0.status == .upcoming &&
                $0.providerId.isEmpty &&
                !$0.rejectedProviderIds.contains(providerID) &&
                !$0.isExpiredAwaitingProviderResponse
            }
        case .accepted:
            return bookings.filter {
                $0.status == .upcoming &&
                $0.providerId == providerID &&
                $0.providerResponseStatus == .accepted
            }
        case .completed:
            return bookings.filter {
                $0.status == .completed &&
                $0.providerId == providerID
            }
        }
    }

    func selectTab(_ tab: ProviderBookingTab) {
        selectedTab = tab
    }

    func manageBooking(_ booking: ServiceBooking) {
        bannerMessage = "Client address: \(booking.address)"
    }

    func clearBanner() {
        bannerMessage = nil
    }

    func acceptBooking(_ booking: ServiceBooking) {
        Task {
            await updateBookingStatus(
                booking: booking,
                status: .upcoming,
                providerResponseStatus: .accepted,
                customerMessage: "\(currentProviderName()) accepted your booking for \(booking.serviceName)."
            )
        }
    }

    func rejectBooking(_ booking: ServiceBooking) {
        Task {
            await rejectOpenBooking(booking)
        }
    }

    func completeBooking(_ booking: ServiceBooking) {
        Task {
            await updateBookingStatus(
                booking: booking,
                status: .completed,
                providerResponseStatus: .accepted,
                customerMessage: "\(currentProviderName()) completed your \(booking.serviceName) service."
            )
        }
    }

    func isProcessing(_ booking: ServiceBooking) -> Bool {
        processingBookingId == booking.id
    }

    private func bindUser() {
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.startObserving(for: user)
            }
            .store(in: &cancellables)

        startObserving(for: authService.currentUser)
    }

    private func startObserving(for user: User?) {
        bookingsObservation?.cancel()
        notificationsObservation?.cancel()
        bookings = []
        unreadNotificationCount = 0
        seenNotificationIDs = []
        expiredBookingCleanupIDs = []
        observedProviderID = nil
        errorMessage = nil
        processingBookingId = nil
        isLoadingBookings = false

        guard let providerID = user?.uid else { return }
        observedProviderID = providerID
        isLoadingBookings = true

        bookingsObservation = bookingService.observeProviderBookings(providerId: providerID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let bookings):
                self.bookings = bookings
                self.isLoadingBookings = false
                self.errorMessage = nil
                self.cleanupExpiredBookings(in: bookings)
            case .failure(let error):
                self.bookings = []
                self.isLoadingBookings = false
                self.errorMessage = error.localizedDescription
            }
        }

        notificationsObservation = bookingService.observeNotifications(userId: providerID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let notifications):
                let previousIDs = Set(self.seenNotificationIDs)
                self.unreadNotificationCount = notifications.filter { !$0.isRead }.count

                for notification in notifications where !notification.isRead && !previousIDs.contains(notification.id) {
                    self.handleNotification(notification)
                }
            case .failure:
                self.unreadNotificationCount = 0
            }
        }
    }

    private func handleNotification(_ notification: BookingNotificationItem) {
        guard seenNotificationIDs.insert(notification.id).inserted else { return }
        bannerMessage = notification.message
        scheduleLocalNotification(message: notification.message)

        guard let providerID = observedProviderID else { return }
        Task {
            try? await bookingService.markNotificationAsRead(
                userId: providerID,
                notificationId: notification.id
            )
        }
    }

    private func cleanupExpiredBookings(in bookings: [ServiceBooking]) {
        for booking in bookings where booking.isExpiredAwaitingProviderResponse {
            guard expiredBookingCleanupIDs.insert(booking.id).inserted else { continue }

            Task {
                try? await bookingService.discardExpiredBooking(booking.id)
            }
        }
    }

    private func updateBookingStatus(
        booking: ServiceBooking,
        status: BookingStatus,
        providerResponseStatus: ProviderResponseStatus,
        customerMessage: String
    ) async {
        guard let provider = authService.currentUser else {
            bannerMessage = "Please sign in again to manage bookings."
            return
        }

        processingBookingId = booking.id
        defer { processingBookingId = nil }

        do {
            guard let latestBooking = try await bookingService.fetchBooking(booking.id) else {
                bannerMessage = "This booking is no longer available."
                return
            }

            if providerResponseStatus == .accepted,
               !latestBooking.providerId.isEmpty,
               latestBooking.providerId != provider.uid {
                bannerMessage = "This booking was already accepted by another provider."
                return
            }

            try await bookingService.updateBooking(booking.id, values: [
                "providerId": provider.uid,
                "providerName": currentProviderName(),
                "status": status.rawValue,
                "providerResponseStatus": providerResponseStatus.rawValue,
                "updatedAt": Date().timeIntervalSince1970
            ])

            try await bookingService.sendNotification(
                to: booking.customerId,
                bookingId: booking.id,
                message: customerMessage
            )

            bannerMessage = customerMessage
        } catch {
            bannerMessage = error.localizedDescription
        }
    }

    private func rejectOpenBooking(_ booking: ServiceBooking) async {
        guard let provider = authService.currentUser else {
            bannerMessage = "Please sign in again to manage bookings."
            return
        }

        processingBookingId = booking.id
        defer { processingBookingId = nil }

        do {
            guard let latestBooking = try await bookingService.fetchBooking(booking.id) else {
                bannerMessage = "This booking is no longer available."
                return
            }

            if !latestBooking.providerId.isEmpty && latestBooking.providerId != provider.uid {
                bannerMessage = "This booking was already accepted by another provider."
                return
            }

            var rejectedProviderIDs = latestBooking.rejectedProviderIds
            if !rejectedProviderIDs.contains(provider.uid) {
                rejectedProviderIDs.append(provider.uid)
            }

            try await bookingService.updateBooking(booking.id, values: [
                "rejectedProviderIds": rejectedProviderIDs,
                "updatedAt": Date().timeIntervalSince1970
            ])

            bannerMessage = "Booking rejected. Other providers can still accept it."
        } catch {
            bannerMessage = error.localizedDescription
        }
    }

    private func scheduleLocalNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "New booking request"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func currentProviderName() -> String {
        let displayName = authService.currentUser?.displayName ?? ""
        return displayName.isEmpty ? "Your cleaner" : displayName
    }
}
