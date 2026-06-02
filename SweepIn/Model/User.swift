//
//  User.swift
//  SweepIn
//
//  Created by apple on 29/04/26.
//

import Foundation

enum UserRole: String, CaseIterable, Identifiable, Codable {
    case customer = "Customer"
    case provider = "Service Provider"

    var id: String { rawValue }

    init?(storedValue: String) {
        switch storedValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "customer":
            self = .customer
        case "service provider", "provider", "serviceprovider", "service_provider":
            self = .provider
        default:
            return nil
        }
    }
}

struct User: Codable {
    let uid: String
    let email: String
    let fullName: String
    let userRole: String
    let phone: String

    var role: UserRole? {
        UserRole(storedValue: userRole)
    }

    var displayName: String {
        let cleanedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanedName.isEmpty {
            return cleanedName
        }

        let emailName = email
            .split(separator: "@")
            .first
            .map(String.init)?
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let emailName, !emailName.isEmpty {
            return emailName.capitalized
        }

        return "User"
    }

    var firstName: String {
        displayName
            .split(separator: " ")
            .first
            .map(String.init) ?? displayName
    }

    var initials: String {
        let letters = displayName
            .split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()

        if !letters.isEmpty {
            return letters
        }

        return String(displayName.prefix(2)).uppercased()
    }

    var roleTitle: String {
        role?.rawValue ?? userRole.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var phoneText: String {
        let cleanedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanedPhone.isEmpty ? "Not added" : cleanedPhone
    }

    var emailText: String {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanedEmail.isEmpty ? "Not added" : cleanedEmail
    }
}
