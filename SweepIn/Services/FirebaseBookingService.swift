//
//  FirebaseBookingService.swift
//  SweepIn
//
//  Created by Codex on 23/05/26.
//

import Foundation
import FirebaseDatabase

final class DatabaseObservationToken {
    private let cancellation: () -> Void
    private var isCancelled = false

    init(cancellation: @escaping () -> Void) {
        self.cancellation = cancellation
    }

    func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        cancellation()
    }

    deinit {
        cancel()
    }
}

protocol BookingServicing {
    func observeCustomerBookings(
        customerId: String,
        onChange: @escaping (Result<[ServiceBooking], Error>) -> Void
    ) -> DatabaseObservationToken
    func observeProviderBookings(
        providerId: String,
        onChange: @escaping (Result<[ServiceBooking], Error>) -> Void
    ) -> DatabaseObservationToken
    func observeNotifications(
        userId: String,
        onChange: @escaping (Result<[BookingNotificationItem], Error>) -> Void
    ) -> DatabaseObservationToken
    func createBooking(payload: [String: Any]) async throws
    func updateBooking(_ bookingId: String, values: [String: Any]) async throws
    func fetchBooking(_ bookingId: String) async throws -> ServiceBooking?
    func fetchProviders() async throws -> [(id: String, name: String)]
    func sendNotification(to userId: String, bookingId: String, message: String) async throws
    func markNotificationAsRead(userId: String, notificationId: String) async throws
    func discardExpiredBooking(_ bookingId: String) async throws
}

final class FirebaseBookingService: BookingServicing {
    static let shared = FirebaseBookingService()

    private let db = Database.database().reference()

    func observeCustomerBookings(
        customerId: String,
        onChange: @escaping (Result<[ServiceBooking], Error>) -> Void
    ) -> DatabaseObservationToken {
        let ref = db.child("bookings")
        let handle = ref.observe(.value) { snapshot in
            let bookings = self.parseBookings(snapshot)
                .filter { $0.customerId == customerId }
                .sorted { $0.scheduledTimestamp > $1.scheduledTimestamp }
            onChange(.success(bookings))
        }

        return DatabaseObservationToken {
            ref.removeObserver(withHandle: handle)
        }
    }

    func observeProviderBookings(
        providerId: String,
        onChange: @escaping (Result<[ServiceBooking], Error>) -> Void
    ) -> DatabaseObservationToken {
        let ref = db.child("bookings")
        let handle = ref.observe(.value) { snapshot in
            let bookings = self.parseBookings(snapshot)
                .filter { booking in
                    let isAssignedToProvider = booking.providerId == providerId
                    let isOpenForProvider = booking.providerId.isEmpty && !booking.rejectedProviderIds.contains(providerId)
                    return isAssignedToProvider || isOpenForProvider
                }
                .sorted { $0.scheduledTimestamp > $1.scheduledTimestamp }
            onChange(.success(bookings))
        }

        return DatabaseObservationToken {
            ref.removeObserver(withHandle: handle)
        }
    }

    func observeNotifications(
        userId: String,
        onChange: @escaping (Result<[BookingNotificationItem], Error>) -> Void
    ) -> DatabaseObservationToken {
        let ref = db.child("notifications").child(userId)
        let handle = ref.observe(.value) { snapshot in
            let notifications: [BookingNotificationItem]
            if let values = snapshot.value as? [String: Any] {
                notifications = values.compactMap { key, value in
                    guard let dictionary = value as? [String: Any] else { return nil }
                    return BookingNotificationItem(
                        id: key,
                        message: dictionary["message"] as? String ?? "",
                        isRead: dictionary["isRead"] as? Bool ?? false,
                        createdAt: Self.double(from: dictionary["createdAt"])
                    )
                }
                .sorted { $0.createdAt > $1.createdAt }
            } else {
                notifications = []
            }

            onChange(.success(notifications))
        }

        return DatabaseObservationToken {
            ref.removeObserver(withHandle: handle)
        }
    }

    func createBooking(payload: [String: Any]) async throws {
        let bookingId = payload["id"] as? String ?? UUID().uuidString
        try await db.child("bookings").child(bookingId).setValue(payload)
    }

    func updateBooking(_ bookingId: String, values: [String: Any]) async throws {
        try await db.child("bookings").child(bookingId).updateChildValues(values)
    }

    func fetchBooking(_ bookingId: String) async throws -> ServiceBooking? {
        let snapshot = try await db.child("bookings").child(bookingId).getData()
        guard let dictionary = snapshot.value as? [String: Any] else { return nil }
        return ServiceBooking(id: bookingId, dictionary: dictionary)
    }

    func fetchProviders() async throws -> [(id: String, name: String)] {
        let snapshot = try await db.child("providers").getData()
        guard let providers = snapshot.value as? [String: Any], !providers.isEmpty else {
            return []
        }

        return providers
            .compactMap { key, value -> (id: String, name: String, rating: Double)? in
                guard let provider = value as? [String: Any] else { return nil }
                let name = (provider["name"] as? String ?? "Cleaner").trimmingCharacters(in: .whitespacesAndNewlines)
                let rating = Self.double(from: provider["rating"])
                return (key, name, rating)
            }
            .sorted { $0.rating > $1.rating }
            .map { ($0.id, $0.name) }
    }

    func sendNotification(to userId: String, bookingId: String, message: String) async throws {
        let notificationRef = db.child("notifications").child(userId).childByAutoId()
        try await notificationRef.setValue([
            "bookingId": bookingId,
            "message": message,
            "createdAt": Date().timeIntervalSince1970,
            "isRead": false
        ])
    }

    func markNotificationAsRead(userId: String, notificationId: String) async throws {
        try await db.child("notifications")
            .child(userId)
            .child(notificationId)
            .child("isRead")
            .setValue(true)
    }

    func discardExpiredBooking(_ bookingId: String) async throws {
        let snapshot = try await db.child("bookings").child(bookingId).getData()
        guard let dictionary = snapshot.value as? [String: Any],
              let booking = ServiceBooking(id: bookingId, dictionary: dictionary),
              booking.status == .upcoming,
              booking.providerResponseStatus == .pending,
              booking.isExpiredAwaitingProviderResponse
        else {
            return
        }

        let now = Date().timeIntervalSince1970
        try await db.child("bookings").child(booking.id).updateChildValues([
            "status": BookingStatus.discarded.rawValue,
            "updatedAt": now
        ])

        let customerMessage = "Your booking for \(booking.serviceName) was not accepted by any provider in time. It has been discarded. Please book a new booking."
        try await sendNotification(
            to: booking.customerId,
            bookingId: booking.id,
            message: customerMessage
        )

        let providerMessage = "A booking request for \(booking.serviceName) was not accepted in time and has been discarded."
        let providers = try await fetchProviders()
        for provider in providers where !provider.id.isEmpty {
            try await sendNotification(
                to: provider.id,
                bookingId: booking.id,
                message: providerMessage
            )
        }
    }

    private func parseBookings(_ snapshot: DataSnapshot) -> [ServiceBooking] {
        guard let values = snapshot.value as? [String: Any] else { return [] }

        return values.compactMap { key, value in
            guard let dictionary = value as? [String: Any] else { return nil }
            return ServiceBooking(id: key, dictionary: dictionary)
        }
    }

    private static func double(from value: Any?) -> Double {
        switch value {
        case let double as Double:
            return double
        case let int as Int:
            return Double(int)
        case let number as NSNumber:
            return number.doubleValue
        case let string as String:
            return Double(string) ?? 0
        default:
            return 0
        }
    }
}
