//
//  BookCleaningView.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//
import SwiftUI

struct BookCleaningView: View {

    @ObservedObject var viewModel: BookCleaningViewModel
    @Binding var selectedTab: Int

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection
                packageCard
                homeSizeSection
                dateSection
                timeSection
                if let safetyMessage = viewModel.safetyMessage {
                    safetyCard(message: safetyMessage)
                }
                addOnsSection
                pricingSection
                confirmButton
                if let latestNotification = viewModel.customerNotifications.first {
                    bookingNotificationCard(notification: latestNotification)
                }
                liveTrackingSection
                recentBookingsSection
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.isDetailsSheetPresented) {
            BookingDetailsSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("Booking update", isPresented: Binding(
            get: { viewModel.alertMessage != nil || viewModel.successMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.alertMessage = nil
                    viewModel.successMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {
                viewModel.alertMessage = nil
                viewModel.successMessage = nil
            }
        } message: {
            Text(viewModel.alertMessage ?? viewModel.successMessage ?? "")
        }
    }
}

// MARK: - Components

private extension BookCleaningView {

    var headerSection: some View {
        HStack(spacing: 16) {
            Button {
                selectedTab = 0
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Book a clean")
                    .font(.title3.bold())

                Text("Pick your service details and confirm when you're ready.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    var packageCard: some View {
        Group {
            if let service = viewModel.selectedService {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(service.accentColor)
                            .frame(width: 72, height: 72)

                        Image(systemName: service.icon)
                            .font(.title2)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(service.name)
                            .font(.title3.bold())

                        Text("\(service.duration) · Tailored for your home")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(service.price)
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.blue.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.blue.opacity(0.2))
                        )
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose a service from Home")
                        .font(.headline)

                    Text("Tap any service card on the Home tab and it will appear here automatically.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Go to Home") {
                        selectedTab = 0
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray.opacity(0.2))
                        )
                )
            }
        }
    }

    var homeSizeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("HOME SIZE")

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.homeSizes) { size in
                    SelectionCard(
                        title: size.title,
                        subtitle: size.subtitle,
                        isSelected: viewModel.selectedHomeSize == size.title
                    ) {
                        viewModel.selectedHomeSize = size.title
                    }
                }
            }
        }
    }

    var dateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("DATE")

            VStack(alignment: .leading, spacing: 10) {
                DatePicker(
                    "Choose a future date",
                    selection: $viewModel.selectedDate,
                    in: viewModel.minimumBookingDate...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)

                Text("Selected: \(viewModel.selectedDateLabel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }

    var timeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("TIME")

            VStack(alignment: .leading, spacing: 12) {
                DatePicker(
                    "Choose time",
                    selection: $viewModel.selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxHeight: 160)

                Text("Selected time: \(viewModel.selectedTimeLabel)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(viewModel.isSelectedTimeAllowed ? Color.primary : Color.orange)
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }

    var addOnsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("ADD-ONS")

            ForEach(viewModel.addOns) { addOn in
                AddOnRow(
                    addOn: addOn,
                    action: {
                        viewModel.toggleAddOn(addOn)
                    }
                )
            }
        }
    }

    var pricingSection: some View {
        VStack(spacing: 16) {
            if let service = viewModel.selectedService {
                priceRow("\(service.name) (\(viewModel.selectedHomeSize))", amount: viewModel.basePrice)
            } else {
                priceRow("Select a service", amount: 0)
            }

            ForEach(viewModel.selectedAddOns) { item in
                priceRow(item.title, amount: item.price)
            }

            if viewModel.discount > 0 {
                priceRow("Booking discount", amount: -viewModel.discount, isDiscount: true)
            }

            Divider()

            HStack {
                Text("Total")
                    .font(.title3.bold())

                Spacer()

                Text("₹\(viewModel.totalPrice)")
                    .font(.title.bold())
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.pink.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.blue.opacity(0.15))
                )
        )
    }

    var confirmButton: some View {
        Button {
            viewModel.presentConfirmationSheet()
        } label: {
            Text(viewModel.selectedService == nil ? "Select service first" : "Confirm booking")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(viewModel.canStartConfirmation ? Color.blue : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .disabled(!viewModel.canStartConfirmation)
    }

    var recentBookingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("MY BOOKINGS")

            bookingFilterSection

            if viewModel.isLoadingBookings {
                ProgressView("Loading your bookings...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let bookingErrorMessage = viewModel.bookingErrorMessage {
                Text(bookingErrorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if viewModel.filteredBookings.isEmpty {
                Text("No bookings found for this status yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(viewModel.filteredBookings) { booking in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(booking.serviceName)
                                .font(.headline)

                            Text(booking.scheduleSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(booking.status.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(booking.status.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(booking.status.backgroundColor)
                            .clipShape(Capsule())
                    }

                    Text("Provider: \(booking.providerDisplayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(booking.customerStatusMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(statusTone(for: booking))

                    Text("Total: ₹\(booking.totalAmount)")
                        .font(.subheadline.weight(.semibold))
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }

    var liveTrackingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("LIVE STATUS")

            if let activeBooking = viewModel.activeBooking {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(activeBooking.serviceName)
                            .font(.headline)

                        Spacer()

                        Text(activeBooking.status.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(activeBooking.status.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(activeBooking.status.backgroundColor)
                            .clipShape(Capsule())
                    }

                    Text(activeBooking.scheduleSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(activeBooking.customerStatusMessage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(statusTone(for: activeBooking))

                    Text("Cleaner: \(activeBooking.providerDisplayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                Text("Your next active booking will appear here with realtime provider updates.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    var bookingFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CustomerBookingFilter.allCases) { filter in
                    Button {
                        viewModel.selectBookingFilter(filter)
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(viewModel.selectedBookingFilter == filter ? .semibold : .regular))
                            .foregroundStyle(viewModel.selectedBookingFilter == filter ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedBookingFilter == filter ? Color.blue : Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .tracking(1.2)
    }

    func priceRow(_ title: String,
                  amount: Int,
                  isDiscount: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(amount < 0 ? "-₹\(abs(amount))" : "₹\(amount)")
                .fontWeight(.semibold)
                .foregroundStyle(isDiscount ? .green : .primary)
        }
    }

    func safetyCard(message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.shield")
                .foregroundStyle(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.orange)

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    func bookingNotificationCard(notification: BookingNotificationItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: notification.isRead ? "bell" : "bell.badge.fill")
                .foregroundStyle(.blue)

            Text(notification.message)
                .font(.subheadline)

            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture {
            viewModel.markNotificationAsRead(notification)
        }
    }

    func statusTone(for booking: ServiceBooking) -> Color {
        switch booking.status {
        case .completed:
            return .green
        case .cancelled:
            return .gray
        case .discarded:
            return .gray
        case .upcoming:
            switch booking.providerResponseStatus {
            case .accepted:
                return .green
            case .rejected:
                return .red
            case .pending:
                return .orange
            }
        }
    }
}

//  - Reusable Components

struct SelectionCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 84)
            .background(isSelected ? Color.blue.opacity(0.08) : .white)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

struct AddOnRow: View {
    let addOn: AddOn
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: addOn.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 48, height: 48)
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(addOn.title)
                        .font(.headline)

                    Text("+₹\(addOn.price)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: addOn.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(addOn.isSelected ? .blue : .gray.opacity(0.6))
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

struct BookingDetailsSheet: View {
    @ObservedObject var viewModel: BookCleaningViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let service = viewModel.selectedService {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(service.name)
                                .font(.title3.bold())

                            Text("\(viewModel.selectedDateLabel) at \(viewModel.selectedTimeLabel)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Total payable: ₹\(viewModel.totalPrice)")
                                .font(.headline)
                                .foregroundStyle(.blue)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Home address")
                            .font(.headline)

                        TextField("Flat / house number, street, city", text: $viewModel.address, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional information")
                            .font(.headline)

                        TextField("Example: I have 1 golden retriever dog and 1 cat.", text: $viewModel.additionalNotes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
            }
            .navigationTitle("Finish booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isSubmitting ? "Saving..." : "Save") {
                        Task {
                            await viewModel.submitBooking()
                        }
                    }
                    .disabled(!viewModel.canConfirmBooking)
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(Router())
}
