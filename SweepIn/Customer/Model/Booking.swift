//
//  Booking.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

import SwiftUI

//  - Model

struct CleaningPackage: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    let price: Int
}

struct HomeSize: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let priceAdjustment: Int
}

struct BookingDate: Identifiable {
    let id = UUID()
    let day: String
    let date: String
}

struct TimeSlot: Identifiable {
    let id = UUID()
    let time: String
    let isAvailable: Bool
}

struct AddOn: Identifiable {
    let id = UUID()
    let title: String
    let price: Int
    let icon: String
    var isSelected: Bool = false
}

struct BookingNotificationItem: Identifiable {
    let id: String
    let message: String
    let isRead: Bool
    let createdAt: TimeInterval
}

enum CustomerBookingFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case upcoming = "Upcoming"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var id: String { rawValue }
}
