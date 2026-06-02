//
//  Home.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

import Foundation
import SwiftUI

//  - Models
struct CleaningService: Identifiable {
    let id: String
    let name: String
    let price: String
    let basePrice: Int
    let duration: String
    let rating: String
    let reviews: String
    let icon: String
    let isPopular: Bool
    let category: String
    let accentColor: Color
}

struct TopCleaner: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    let specialty: String
    let rating: String
    let avatarColor: Color
}

enum ServiceFilter: String, CaseIterable {
    case all     = "All"
    case regular = "Regular"
    case deep    = "Deep"
    case moveOut = "Move-out"
}
