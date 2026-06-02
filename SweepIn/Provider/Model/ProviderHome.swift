//
//  ProviderHome.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

import Foundation
import SwiftUI

struct ProviderService: Identifiable {
    let id = UUID()
    let name: String
    let price: String
    let rating: String
    let reviews: String
    let icon: String
    let isPopular: Bool
    let accentColor: Color
}

struct ProviderCleaner: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    let specialty: String
    let rating: String
    let avatarColor: Color
}
