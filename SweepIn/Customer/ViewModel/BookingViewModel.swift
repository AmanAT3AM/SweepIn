//
//  BookingViewModel.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

import Foundation
import Combine
import FirebaseDatabase
import UserNotifications

@MainActor
final class BookCleaningViewModel: ObservableObject {

    @Published var selectedService: CleaningService?
    @Published var selectedHomeSize: String = "2 BHK"
    @Published var selectedDate: Date
    @Published var selectedTime: Date
    @Published var address: String = ""
    @Published var additionalNotes: String = ""
    @Published var addOns: [AddOn]
    @Published var isSubmitting = false
    @Published var isDetailsSheetPresented = false
    @Published var alertMessage: String?
    @Published var successMessage: String?
    @Published var bookings: [ServiceBooking] = []
    @Published var customerNotifications: [BookingNotificationItem] = []
    @Published var selectedBookingFilter: CustomerBookingFilter = .all
    @Published var isLoadingBookings = false
    @Published var bookingErrorMessage: String?
    @Published var selectedDiscount: Int = 0

    let homeSizes: [HomeSize] = [
        .init(title: "1 BHK", subtitle: "Up to 600 sq ft", priceAdjustment: 0),
        .init(title: "2 BHK", subtitle: "600-1000 sq ft", priceAdjustment: 300),
        .init(title: "3 BHK", subtitle: "1000-1400 sq ft", priceAdjustment: 650),
        .init(title: "4+ BHK", subtitle: "1400+ sq ft", priceAdjustment: 1050)
    ]

    private let authService: AuthService
    private let bookingService: BookingServicing
    private let db = Database.database().reference()
    private var cancellables = Set<AnyCancellable>()
    private var bookingsObservation: DatabaseObservationToken?
    private var notificationsObservation: DatabaseObservationToken?
    private var seenNotificationIDs = Set<String>()
    private var expiredBookingCleanupIDs = Set<String>()
    private let discountOptions = [50, 60, 100, 120, 199]

    init(
        authService: AuthService? = nil,
        bookingService: BookingServicing = FirebaseBookingService.shared
    ) {
        let calendar = Calendar.current
        let nextDay = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let nextDayStart = calendar.startOfDay(for: nextDay)

        self.authService = authService ?? AuthService.shared
        self.bookingService = bookingService
        self.selectedDate = nextDayStart
        self.selectedTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: nextDayStart) ?? nextDayStart
        self.addOns = [
            AddOn(title: "Inside fridge", price: 249, icon: "snowflake", isSelected: false),
            AddOn(title: "Inside oven", price: 349, icon: "flame", isSelected: false),
            AddOn(title: "Balcony clean", price: 149, icon: "building.2", isSelected: false)
        ]

        bindUser()
    }

    deinit {
        bookingsObservation?.cancel()
        notificationsObservation?.cancel()
    }

    var minimumBookingDate: Date {
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
    }

    var selectedAddOns: [AddOn] {
        addOns.filter(\.isSelected)
    }

    var selectedDateLabel: String {
        Self.dateFormatter.string(from: selectedDate)
    }

    var selectedTimeLabel: String {
        Self.timeFormatter.string(from: selectedTime)
    }

    var selectedTimeHour: Int {
        Calendar.current.component(.hour, from: selectedTime)
    }

    var isSelectedTimeAllowed: Bool {
        selectedTimeHour >= 7 && selectedTimeHour < 20
    }

    var safetyMessage: String? {
        guard !isSelectedTimeAllowed else { return nil }
        return "For safety, bookings are available only between 7:00 AM and 8:00 PM."
    }

    var baseServicePrice: Int {
        selectedService?.basePrice ?? 0
    }

    var selectedHomeSizeDetails: HomeSize? {
        homeSizes.first(where: { $0.title == selectedHomeSize })
    }

    var homeSizeAdjustment: Int {
        selectedHomeSizeDetails?.priceAdjustment ?? 0
    }

    var basePrice: Int {
        baseServicePrice + homeSizeAdjustment
    }

    var discount: Int {
        guard selectedService != nil else { return 0 }
        return selectedDiscount
    }

    var addOnsTotal: Int {
        selectedAddOns.reduce(0) { $0 + $1.price }
    }

    var totalPrice: Int {
        max(basePrice + addOnsTotal - discount, 0)
    }

    var canStartConfirmation: Bool {
        selectedService != nil && isSelectedTimeAllowed
    }

    var canConfirmBooking: Bool {
        canStartConfirmation &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSubmitting
    }

    var filteredBookings: [ServiceBooking] {
        switch selectedBookingFilter {
        case .all:
            return bookings.filter { $0.status != .discarded }
        case .upcoming:
            return bookings.filter { $0.status == .upcoming && !$0.isExpiredAwaitingProviderResponse }
        case .completed:
            return bookings.filter { $0.status == .completed }
        case .cancelled:
            return bookings.filter { $0.status == .cancelled }
        }
    }

    var activeBooking: ServiceBooking? {
        bookings
            .filter { $0.status == .upcoming && !$0.isExpiredAwaitingProviderResponse }
            .sorted { $0.scheduledTimestamp < $1.scheduledTimestamp }
            .first
    }

    func selectService(_ service: CleaningService) {
        selectedService = service
        rollDiscount()
    }

    func toggleAddOn(_ addOn: AddOn) {
        guard let index = addOns.firstIndex(where: { $0.id == addOn.id }) else { return }
        addOns[index].isSelected.toggle()
    }

    func selectBookingFilter(_ filter: CustomerBookingFilter) {
        selectedBookingFilter = filter
    }

    func presentConfirmationSheet() {
        guard selectedService != nil else {
            alertMessage = "Please choose a service from Home before you continue."
            return
        }

        guard isSelectedTimeAllowed else {
            alertMessage = safetyMessage
            return
        }

        isDetailsSheetPresented = true
    }

    func submitBooking() async {
        guard let selectedService else {
            alertMessage = "Please select a service first."
            return
        }

        let cleanedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedNotes = additionalNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedAddress.isEmpty else {
            alertMessage = "Please add the home address for the cleaner."
            return
        }

        guard isSelectedTimeAllowed else {
            alertMessage = safetyMessage
            return
        }

        guard let currentUser = authService.currentUser else {
            alertMessage = "Please sign in again before placing a booking."
            return
        }

        isSubmitting = true

        do {
            let providers = try await bookingService.fetchProviders()
            let bookingID = Database.database().reference().child("bookings").childByAutoId().key ?? UUID().uuidString
            let scheduledAt = combinedScheduleDate()
            let now = Date().timeIntervalSince1970

            let addOnPayload = selectedAddOns.map {
                BookingAddOn(title: $0.title, price: $0.price, icon: $0.icon).firebaseValue
            }

            let bookingPayload: [String: Any] = [
                "id": bookingID,
                "customerId": currentUser.uid,
                "customerName": currentUser.displayName,
                "customerPhone": currentUser.phone,
                "providerId": "",
                "providerName": "",
                "serviceId": selectedService.id,
                "serviceName": selectedService.name,
                "serviceCategory": selectedService.category,
                "serviceDuration": selectedService.duration,
                "homeSize": selectedHomeSize,
                "scheduledDate": selectedDateLabel,
                "scheduledTime": selectedTimeLabel,
                "scheduledTimestamp": scheduledAt.timeIntervalSince1970,
                "address": cleanedAddress,
                "additionalNotes": cleanedNotes,
                "addOns": addOnPayload,
                "subtotal": basePrice + addOnsTotal,
                "discount": discount,
                "totalAmount": totalPrice,
                "status": BookingStatus.upcoming.rawValue,
                "providerResponseStatus": ProviderResponseStatus.pending.rawValue,
                "rejectedProviderIds": [],
                "createdAt": now,
                "updatedAt": now
            ]

            try await bookingService.createBooking(payload: bookingPayload)
            try await persistCustomerStats(for: currentUser.uid)

            for provider in providers where !provider.id.isEmpty {
                try await bookingService.sendNotification(
                    to: provider.id,
                    bookingId: bookingID,
                    message: "\(currentUser.displayName) booked \(selectedService.name) for \(selectedDateLabel) at \(selectedTimeLabel)."
                )
            }

            try await bookingService.sendNotification(
                to: currentUser.uid,
                bookingId: bookingID,
                message: "Your booking request for \(selectedService.name) has been shared with available providers."
            )

            successMessage = "Booking confirmed for \(selectedDateLabel) at \(selectedTimeLabel)."
            isDetailsSheetPresented = false
            resetBookingDraft()
        } catch {
            alertMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    func markNotificationAsRead(_ notification: BookingNotificationItem) {
        guard let currentUserID = authService.currentUser?.uid else { return }

        Task {
            try? await db.child("notifications")
                .child(currentUserID)
                .child(notification.id)
                .child("isRead")
                .setValue(true)
        }
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
        customerNotifications = []
        bookingErrorMessage = nil
        seenNotificationIDs = []
        isLoadingBookings = false

        guard let customerID = user?.uid else { return }
        isLoadingBookings = true

        bookingsObservation = bookingService.observeCustomerBookings(customerId: customerID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let bookings):
                self.bookings = bookings
                self.isLoadingBookings = false
                self.bookingErrorMessage = nil
                self.cleanupExpiredBookings(in: bookings)
            case .failure(let error):
                self.bookings = []
                self.isLoadingBookings = false
                self.bookingErrorMessage = error.localizedDescription
            }
        }

        notificationsObservation = bookingService.observeNotifications(userId: customerID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let notifications):
                let previousIDs = Set(self.customerNotifications.map(\.id))
                let incomingIDs = Set(notifications.map(\.id))
                let newIDs = incomingIDs.subtracting(previousIDs)

                self.customerNotifications = notifications

                for notification in notifications where newIDs.contains(notification.id) {
                    self.handleNotification(notification)
                }
            case .failure:
                self.customerNotifications = []
            }
        }
    }

    private func handleNotification(_ notification: BookingNotificationItem) {
        guard seenNotificationIDs.insert(notification.id).inserted else { return }
        scheduleLocalNotification(title: "Booking update", message: notification.message)
    }

    private func cleanupExpiredBookings(in bookings: [ServiceBooking]) {
        for booking in bookings where booking.isExpiredAwaitingProviderResponse {
            guard expiredBookingCleanupIDs.insert(booking.id).inserted else { continue }

            Task {
                try? await bookingService.discardExpiredBooking(booking.id)
            }
        }
    }

    private func scheduleLocalNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func combinedScheduleDate() -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

        var merged = DateComponents()
        merged.year = dateComponents.year
        merged.month = dateComponents.month
        merged.day = dateComponents.day
        merged.hour = timeComponents.hour
        merged.minute = timeComponents.minute

        return calendar.date(from: merged) ?? selectedDate
    }

    private func resetBookingDraft() {
        let calendar = Calendar.current
        let nextDay = minimumBookingDate
        selectedDate = nextDay
        selectedTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: nextDay) ?? nextDay
        address = ""
        additionalNotes = ""
        selectedDiscount = selectedService == nil ? 0 : (discountOptions.randomElement() ?? 0)
        addOns = addOns.map { addOn in
            AddOn(title: addOn.title, price: addOn.price, icon: addOn.icon, isSelected: false)
        }
    }

    private func rollDiscount() {
        selectedDiscount = discountOptions.randomElement() ?? 0
    }

    private func persistCustomerStats(for uid: String) async throws {
        let statsRef = db.child("users").child(uid).child("stats")
        let snapshot = try await statsRef.getData()
        let currentStats = snapshot.value as? [String: Any] ?? [:]

        let bookingCount = (Self.number(from: currentStats["bookingCount"])?.intValue ?? 0) + 1
        let totalSpent = (Self.number(from: currentStats["totalSpent"])?.intValue ?? 0) + totalPrice

        try await statsRef.setValue([
            "bookingCount": bookingCount,
            "totalSpent": totalSpent
        ])
    }

    private static func number(from value: Any?) -> NSNumber? {
        switch value {
        case let int as Int:
            return NSNumber(value: int)
        case let double as Double:
            return NSNumber(value: double)
        case let number as NSNumber:
            return number
        case let string as String:
            if let int = Int(string) {
                return NSNumber(value: int)
            }
            if let double = Double(string) {
                return NSNumber(value: double)
            }
            return nil
        default:
            return nil
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}
