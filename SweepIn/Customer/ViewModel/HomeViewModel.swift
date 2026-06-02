//
//  HomeViewModel.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

import Foundation
import Combine
import SwiftUI
import FirebaseDatabase

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var searchText = ""
    @Published var selectedFilter: ServiceFilter = .all
    @Published var userName = "Customer"
    @Published var allServices: [CleaningService] = []
    @Published var topCleaners: [TopCleaner] = []

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

    let promoCode = "CLEANLY20"

    var filteredServices: [CleaningService] {
        switch selectedFilter {
        case .all:     return allServices
        case .regular: return allServices.filter { $0.name.lowercased().contains("standard") }
        case .deep:    return allServices.filter { $0.name.lowercased().contains("deep") }
        case .moveOut: return allServices.filter { $0.name.lowercased().contains("move") }
        }
    }

    func selectFilter(_ filter: ServiceFilter) { selectedFilter = filter }
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
        userName = user?.firstName ?? "Customer"
    }

    private func loadHomeData() async {
        await loadServices()
        await loadCleaners()
    }

    private func loadServices() async {
        do {
            let snapshot = try await db.child("services").getData()
            guard let servicesDict = snapshot.value as? [String: Any], !servicesDict.isEmpty else {
                allServices = []
                return
            }

            allServices = servicesDict.compactMap { element -> CleaningService? in

                let value = element.value

                guard let item = value as? [String: Any] else {
                    return nil
                }

                let name = stringValue(item["title"]) ?? stringValue(item["name"]) ?? "Service"
                let category = (stringValue(item["category"]) ?? "").lowercased()

                let priceNumber = intValue(item["price"])
                let resolvedPrice = priceNumber ?? fallbackPrice(for: name, category: category)

                let priceText = stringValue(item["priceText"])
                    ?? "From ₹\(resolvedPrice)"

                let ratingNumber = doubleValue(item["rating"]) ?? 0

                let reviews = stringValue(item["reviews"]) ?? "0"

                let icon = stringValue(item["icon"]) ?? "sparkles"
                let duration = stringValue(item["duration"]) ?? fallbackDuration(for: name, category: category)

//                let isPopular = boolValue(item["isPopular"]) ?? ratingNumber >= 4.8
                let isPopular = boolValue(item["isPopular"]) ?? (ratingNumber >= 4.8)

                return CleaningService(
                    id: element.key,
                    name: name,
                    price: priceText,
                    basePrice: resolvedPrice,
                    duration: duration,
                    rating: String(format: "%.1f", ratingNumber),
                    reviews: reviews,
                    icon: icon,
                    isPopular: isPopular,
                    category: category,
                    accentColor: colorForCategory(category)
                )
            }
            .sorted { $0.name < $1.name }
        } catch {
            allServices = []
        }
    }

    private func loadCleaners() async {
        do {
            let providersSnapshot = try await db.child("providers").getData()
            if let providersDict = providersSnapshot.value as? [String: Any], !providersDict.isEmpty {
                topCleaners = providersDict.compactMap(mapCleaner(from:))
                    .sorted { Double($0.rating) ?? 0 > Double($1.rating) ?? 0 }
                return
            }

            let cleanersSnapshot = try await db.child("cleaners").getData()
            guard let cleanersDict = cleanersSnapshot.value as? [String: Any], !cleanersDict.isEmpty else {
                topCleaners = []
                return
            }

            topCleaners = cleanersDict.compactMap(mapCleaner(from:))
                .sorted { Double($0.rating) ?? 0 > Double($1.rating) ?? 0 }
        } catch {
            topCleaners = []
        }
    }

    private func mapCleaner(from element: (key: String, value: Any)) -> TopCleaner? {
        guard let item = element.value as? [String: Any] else { return nil }
        let name = stringValue(item["name"]) ?? "Cleaner"
        let specialty = stringValue(item["specialist"]) ?? stringValue(item["specialty"]) ?? "Home cleaning"
        let rating = doubleValue(item["rating"]) ?? 0

        return TopCleaner(
            name: name,
            initials: initials(from: name),
            specialty: specialty,
            rating: String(format: "%.2f", rating),
            avatarColor: .sky
        )
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

    private func fallbackPrice(for name: String, category: String) -> Int {
        let key = "\(name) \(category)".lowercased()
        if key.contains("deep") { return 1499 }
        if key.contains("move") { return 2199 }
        if key.contains("kitchen") { return 899 }
        if key.contains("bath") { return 699 }
        return 999
    }

    private func fallbackDuration(for name: String, category: String) -> String {
        let key = "\(name) \(category)".lowercased()
        if key.contains("deep") { return "4-6 hrs" }
        if key.contains("move") { return "5-7 hrs" }
        if key.contains("kitchen") { return "2-3 hrs" }
        if key.contains("bath") { return "1-2 hrs" }
        return "2-4 hrs"
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

        if value is Bool {
            return nil
        }

        switch value {

        case let v as Double:
            return v

        case let v as Int:
            return Double(v)

        case let v as NSNumber:
            return v.doubleValue

        case let v as String:
            return Double(v)

        default:
            return nil
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
