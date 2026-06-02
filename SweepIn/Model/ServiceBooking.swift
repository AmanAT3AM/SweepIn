//
//  ServiceBooking.swift
//  SweepIn
//
//  Created by Codex on 23/05/26.
//

import Foundation
import SwiftUI

enum BookingStatus: String, CaseIterable, Identifiable, Codable {
    case upcoming = "Upcoming"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case discarded = "Discarded"

    var id: String { rawValue }

    init(databaseValue: String) {
        switch databaseValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "completed":
            self = .completed
        case "cancelled", "canceled", "cancled":
            self = .cancelled
        case "discarded", "expired":
            self = .discarded
        default:
            self = .upcoming
        }
    }

    var color: Color {
        switch self {
        case .upcoming:
            return Color(red: 0.20, green: 0.40, blue: 1.0)
        case .completed:
            return Color(red: 0.13, green: 0.70, blue: 0.45)
        case .cancelled:
            return Color(red: 0.13, green: 0.70, blue: 0.40)
        case .discarded:
            return Color(red: 0.55, green: 0.55, blue: 0.60)
        }
    }

    var backgroundColor: Color {
        color.opacity(0.12)
    }
}

enum ProviderResponseStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case accepted = "Accepted"
    case rejected = "Rejected"

    init(databaseValue: String) {
        switch databaseValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "accepted":
            self = .accepted
        case "rejected":
            self = .rejected
        default:
            self = .pending
        }
    }
}

struct BookingAddOn: Identifiable, Hashable {
    let id: String
    let title: String
    let price: Int
    let icon: String

    init(id: String = UUID().uuidString, title: String, price: Int, icon: String) {
        self.id = id
        self.title = title
        self.price = price
        self.icon = icon
    }

    init?(dictionary: [String: Any]) {
        let title = (dictionary["title"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        self.id = dictionary["id"] as? String ?? UUID().uuidString
        self.title = title
        self.price = Self.number(from: dictionary["price"])
        self.icon = dictionary["icon"] as? String ?? "sparkles"
    }

    var firebaseValue: [String: Any] {
        [
            "id": id,
            "title": title,
            "price": price,
            "icon": icon
        ]
    }

    private static func number(from value: Any?) -> Int {
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

struct ServiceBooking: Identifiable, Hashable {
    let id: String
    let customerId: String
    let customerName: String
    let customerPhone: String
    let providerId: String
    let providerName: String
    let providerResponseStatus: ProviderResponseStatus
    let serviceId: String
    let serviceName: String
    let serviceCategory: String
    let serviceDuration: String
    let homeSize: String
    let scheduledDate: String
    let scheduledTime: String
    let scheduledTimestamp: TimeInterval
    let address: String
    let additionalNotes: String
    let addOns: [BookingAddOn]
    let subtotal: Int
    let discount: Int
    let totalAmount: Int
    let status: BookingStatus
    let rejectedProviderIds: [String]
    let createdAt: TimeInterval
    let updatedAt: TimeInterval?

    init?(id: String, dictionary: [String: Any]) {
        let resolvedID = (dictionary["id"] as? String ?? id).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolvedID.isEmpty else { return nil }

        self.id = resolvedID
        self.customerId = dictionary["customerId"] as? String ?? ""
        self.customerName = dictionary["customerName"] as? String ?? ""
        self.customerPhone = dictionary["customerPhone"] as? String ?? ""
        self.providerId = dictionary["providerId"] as? String ?? ""
        self.providerName = dictionary["providerName"] as? String ?? ""
        self.providerResponseStatus = ProviderResponseStatus(databaseValue: dictionary["providerResponseStatus"] as? String ?? "")
        self.serviceId = dictionary["serviceId"] as? String ?? ""
        self.serviceName = dictionary["serviceName"] as? String ?? "Cleaning"
        self.serviceCategory = dictionary["serviceCategory"] as? String ?? ""
        self.serviceDuration = dictionary["serviceDuration"] as? String ?? ""
        self.homeSize = dictionary["homeSize"] as? String ?? ""
        self.scheduledDate = dictionary["scheduledDate"] as? String ?? ""
        self.scheduledTime = dictionary["scheduledTime"] as? String ?? ""
        self.scheduledTimestamp = Self.double(from: dictionary["scheduledTimestamp"])
        self.address = dictionary["address"] as? String ?? ""
        self.additionalNotes = dictionary["additionalNotes"] as? String ?? ""
        self.addOns = (dictionary["addOns"] as? [[String: Any]] ?? []).compactMap(BookingAddOn.init)
        self.subtotal = Self.number(from: dictionary["subtotal"])
        self.discount = Self.number(from: dictionary["discount"])
        self.totalAmount = Self.number(from: dictionary["totalAmount"])
        self.status = BookingStatus(databaseValue: dictionary["status"] as? String ?? "")
        self.rejectedProviderIds = Self.stringArray(from: dictionary["rejectedProviderIds"])
        self.createdAt = Self.double(from: dictionary["createdAt"])
        let updatedAt = Self.double(from: dictionary["updatedAt"])
        self.updatedAt = updatedAt == 0 ? nil : updatedAt
    }

    var isAwaitingProvider: Bool {
        providerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isExpiredAwaitingProviderResponse: Bool {
        guard isAwaitingProvider, scheduledTimestamp > 0 else { return false }
        return scheduledTimestamp < Date().timeIntervalSince1970
    }

    var providerDisplayName: String {
        let cleanedName = providerName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanedName.isEmpty {
            return cleanedName
        }

        return isAwaitingProvider ? "Awaiting provider" : "Assigned provider"
    }

    var scheduleSummary: String {
        "\(scheduledDate) at \(scheduledTime)"
    }

    var providerScheduleSummary: String {
        "\(scheduledDate) · \(scheduledTime)"
    }

    var customerStatusMessage: String {
        switch status {
        case .completed:
            return "Cleaning completed"
        case .cancelled:
            return "Booking cancelled"
        case .discarded:
            return "This booking was not accepted by any provider in time. Please book a new one."
        case .upcoming:
            switch providerResponseStatus {
            case .accepted:
                return "\(providerDisplayName) accepted your booking"
            case .rejected:
                return "Provider rejected this booking"
            case .pending:
                return isAwaitingProvider ? "Waiting for provider acceptance" : "Booking scheduled"
            }
        }
    }

    var providerClientInitials: String {
        let parts = customerName.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        let initials = (first + second).uppercased()
        return initials.isEmpty ? "CL" : initials
    }

    private static func number(from value: Any?) -> Int {
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

    private static func stringArray(from value: Any?) -> [String] {
        if let values = value as? [String] {
            return values
        }

        if let values = value as? [Any] {
            return values.compactMap { $0 as? String }
        }

        return []
    }
}
