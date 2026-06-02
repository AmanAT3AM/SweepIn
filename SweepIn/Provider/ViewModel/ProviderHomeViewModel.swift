//
//  ProviderHomeViewModel.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

import Foundation
import SwiftUI
import Combine
import FirebaseDatabase

@MainActor
final class ProviderHomeViewModel: ObservableObject {

    @Published var searchText = ""
    @Published var userName = "Provider"
    @Published var services: [ProviderService] = []
    @Published var topCleaners: [ProviderCleaner] = []
    @Published var providerExpertise: [String] = []
    @Published var expertiseDraft = ""
    @Published var expertiseMessage: String?

    private let authService: AuthService
    private let db = Database.database().reference()
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthService? = nil) {
        self.authService = authService ?? AuthService.shared
        bindUser()
        Task {
            await loadHomeData()
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var promoCode: String { "CLEANLY20" }
    func claimPromo() { }

    func seeAllServices() { }
    func seeAllCleaners() { }

    private func bindUser() {
        apply(user: authService.currentUser)

        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.apply(user: user)
                Task { [weak self] in
                    await self?.loadHomeData()
                }
            }
            .store(in: &cancellables)
    }

    private func apply(user: User?) {
        userName = user?.firstName ?? "Provider"
    }

    private func loadHomeData() async {
        await loadServices()
        await loadTopCleaners()
        await loadProviderExpertise()
    }

    private func loadServices() async {
        do {
            let snapshot = try await db.child("services").getData()
            guard let servicesDict = snapshot.value as? [String: Any], !servicesDict.isEmpty else {
                services = []
                return
            }

            services = servicesDict.compactMap { element -> ProviderService? in

                let value = element.value

                guard let item = value as? [String: Any] else {
                    return nil
                }

                let name = stringValue(item["title"]) ?? stringValue(item["name"]) ?? "Service"

                let priceNumber = intValue(item["price"])

                let priceText = stringValue(item["priceText"])
                    ?? (priceNumber != nil ? "From ₹\(priceNumber!)" : "From ₹0")

                let ratingNumber = doubleValue(item["rating"]) ?? 0

                let reviews = stringValue(item["reviews"]) ?? "0"

                let icon = stringValue(item["icon"]) ?? "sparkles"

                let category = (stringValue(item["category"]) ?? "").lowercased()

                let isPopular = boolValue(item["isPopular"]) ?? (ratingNumber >= 4.8)

                return ProviderService(
                    name: name,
                    price: priceText,
                    rating: String(format: "%.1f", ratingNumber),
                    reviews: reviews,
                    icon: icon,
                    isPopular: isPopular,
                    accentColor: colorForCategory(category)
                )
            }
            .sorted { $0.name < $1.name }
        } catch {
            services = []
        }
    }

    private func loadTopCleaners() async {
        do {
            let providersSnapshot = try await db.child("providers").getData()
            guard let providersDict = providersSnapshot.value as? [String: Any], !providersDict.isEmpty else {
                topCleaners = []
                return
            }

            topCleaners = providersDict.compactMap { _, value in
                guard let item = value as? [String: Any] else { return nil }
                let name = stringValue(item["name"]) ?? "Cleaner"
                let specialty = stringValue(item["specialist"]) ?? stringValue(item["specialty"]) ?? "Home cleaning"
                let rating = doubleValue(item["rating"]) ?? 0

                return ProviderCleaner(
                    name: name,
                    initials: initials(from: name),
                    specialty: specialty,
                    rating: String(format: "%.1f", rating),
                    avatarColor: .sky
                )
            }
            .sorted { Double($0.rating) ?? 0 > Double($1.rating) ?? 0 }
        } catch {
            topCleaners = []
        }
    }

    func addExpertise() {
        let cleanedValue = expertiseDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedValue.isEmpty else {
            expertiseMessage = "Please enter a service you are expert in."
            return
        }

        guard !providerExpertise.contains(where: { $0.caseInsensitiveCompare(cleanedValue) == .orderedSame }) else {
            expertiseMessage = "This service is already added."
            return
        }

        providerExpertise.append(cleanedValue)
        providerExpertise.sort()
        expertiseDraft = ""
        expertiseMessage = "Service expertise updated."

        Task {
            await persistProviderExpertise()
        }
    }

    func removeExpertise(_ value: String) {
        providerExpertise.removeAll { $0 == value }

        Task {
            await persistProviderExpertise()
        }
    }

    private func loadProviderExpertise() async {
        guard let providerID = authService.currentUser?.uid else {
            providerExpertise = []
            return
        }

        do {
            let snapshot = try await db.child("providers").child(providerID).child("expertise").getData()
            if let values = snapshot.value as? [String] {
                providerExpertise = values.sorted()
                return
            }

            if let values = snapshot.value as? [Any] {
                providerExpertise = values.compactMap { $0 as? String }.sorted()
                return
            }

            let providerSnapshot = try await db.child("providers").child(providerID).getData()
            let providerDict = providerSnapshot.value as? [String: Any] ?? [:]
            let fallback = stringValue(providerDict["specialist"]) ?? stringValue(providerDict["specialty"]) ?? ""
            providerExpertise = fallback.isEmpty ? [] : [fallback]
        } catch {
            providerExpertise = []
        }
    }

    private func persistProviderExpertise() async {
        guard let providerID = authService.currentUser?.uid else { return }

        let joinedExpertise = providerExpertise.joined(separator: ", ")

        do {
            try await db.child("providers").child(providerID).updateChildValues([
                "name": authService.currentUser?.displayName ?? userName,
                "specialist": joinedExpertise,
                "specialty": joinedExpertise,
                "expertise": providerExpertise
            ])
        } catch {
            expertiseMessage = error.localizedDescription
        }
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }

    private func colorForCategory(_ category: String) -> Color {
        if category.contains("deep") { return .sky3 }
        if category.contains("move") { return .coral2 }
        if category.contains("office") { return .mint2 }
        return .sky3
    }

    private func stringValue(_ value: Any?) -> String? {
        switch value {
        case let v as String:
            let trimmed = v.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case let v as NSNumber:
            return v.stringValue
        default:
            return nil
        }
    }

    private func intValue(_ value: Any?) -> Int? {
        switch value {
        case let v as Int: return v
        case let v as NSNumber: return v.intValue
        case let v as String: return Int(v)
        default: return nil
        }
    }

    private func doubleValue(_ value: Any?) -> Double? {
        switch value {
        case let v as Double: return v
        case let v as NSNumber: return v.doubleValue
        case let v as String: return Double(v)
        default: return nil
        }
    }

    private func boolValue(_ value: Any?) -> Bool? {
        switch value {
        case let v as Bool: return v
        case let v as NSNumber: return v.boolValue
        case let v as String: return ["true", "1", "yes"].contains(v.lowercased())
        default: return nil
        }
    }
}
