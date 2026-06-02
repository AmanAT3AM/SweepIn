//
//  ProviderBookCleaningView.swift
//  SweepIn
//
//  Created by apple on 28/04/26.
//

import SwiftUI

// MARK: - Provider Booking View

struct ProviderBookingView: View {

    @StateObject private var viewModel = ProviderBookingViewModel()

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 1.0)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("My bookings")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)

                    if viewModel.unreadNotificationCount > 0 {
                        Text("\(viewModel.unreadNotificationCount) new booking update\(viewModel.unreadNotificationCount == 1 ? "" : "s")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)

                if let bannerMessage = viewModel.bannerMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.blue)

                        Text(bannerMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)

                        Spacer()

                        Button {
                            viewModel.clearBanner()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }

                // Tab Selector
                BookingTabSelectorView(viewModel: viewModel)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                // Booking List
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        if viewModel.isLoadingBookings {
                            ProgressView("Loading bookings...")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else if viewModel.filteredBookings.isEmpty {
                            Text(emptyStateMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        ForEach(viewModel.filteredBookings) { booking in
                            BookingCardView(booking: booking, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    private var emptyStateMessage: String {
        switch viewModel.selectedTab {
        case .new:
            return "New customer requests will appear here instantly."
        case .accepted:
            return "Accepted bookings will move here automatically."
        case .completed:
            return "Completed jobs will appear here after you finish them."
        }
    }
}

// MARK: - Tab Selector

struct BookingTabSelectorView: View {

    @ObservedObject var viewModel: ProviderBookingViewModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProviderBookingTab.allCases) { tab in
                Button {
                    viewModel.selectTab(tab)
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 15, weight: viewModel.selectedTab == tab ? .semibold : .regular))
                        .foregroundColor(
                            viewModel.selectedTab == tab
                            ? Color(red: 0.20, green: 0.40, blue: 1.0)
                            : Color.gray
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            viewModel.selectedTab == tab
                            ? Color.white
                            : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(4)
        .background(Color(red: 0.93, green: 0.93, blue: 0.97))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Booking Card

struct BookingCardView: View {

    let booking: ServiceBooking
    @ObservedObject var viewModel: ProviderBookingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Top row — service name + status badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.serviceName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)

                    Text(booking.providerScheduleSummary)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    if booking.status == .upcoming && booking.providerId.isEmpty {
                        Text("Waiting for your response")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                    } else if booking.status == .upcoming {
                        Text("Accepted by you")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                // Status badge
                Text(booking.status.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(booking.status.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(booking.status.backgroundColor)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 16)

            Divider()
                .padding(.bottom, 14)

            // Bottom row — avatar + client info + action button
            HStack(spacing: 12) {

                // Avatar
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.20, green: 0.40, blue: 1.0).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Text(booking.providerClientInitials)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(red: 0.20, green: 0.40, blue: 1.0))
                }

                // Client name + price · BHK
                VStack(alignment: .leading, spacing: 3) {
                    Text(booking.customerName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    Text("₹\(booking.totalAmount) · \(booking.homeSize)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    if !booking.additionalNotes.isEmpty {
                        Text(booking.additionalNotes)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Action button
                actionButton
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch booking.status {
        case .upcoming:
            if booking.providerId.isEmpty {
                HStack(spacing: 8) {
                    Button {
                        viewModel.acceptBooking(booking)
                    } label: {
                        Text(viewModel.isProcessing(booking) ? "Saving..." : "Accept")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.green.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(viewModel.isProcessing(booking))

                    Button {
                        viewModel.rejectBooking(booking)
                    } label: {
                        Text(viewModel.isProcessing(booking) ? "Saving..." : "Reject")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(viewModel.isProcessing(booking))
                }
            } else {
                Button {
                    viewModel.completeBooking(booking)
                } label: {
                    Text(viewModel.isProcessing(booking) ? "Saving..." : "Complete")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.13, green: 0.70, blue: 0.45))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(Color(red: 0.13, green: 0.70, blue: 0.45).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.isProcessing(booking))
            }

        case .completed, .cancelled, .discarded:
            Button {
                viewModel.manageBooking(booking)
            } label: {
                Text("Details")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.20, green: 0.40, blue: 1.0))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Color(red: 0.20, green: 0.40, blue: 1.0).opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProviderBookingView()
}
