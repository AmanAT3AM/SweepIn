//
//  ProviderBooking.swift
//  SweepIn
//
//  Created by apple on 28/04/26.
//

import Foundation

enum ProviderBookingTab: String, CaseIterable, Identifiable {
    case new = "New Bookings"
    case accepted = "Accepted"
    case completed = "Completed"

    var id: String { rawValue }
}
