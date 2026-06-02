//
//  ProviderProfile.swift
//  SweepIn
//
//  Created by apple on 28/04/26.
//

import Foundation
import SwiftUI

// MARK: - Models

struct ProfileStats: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct ProfileMenuItems: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tint: Color
    var badge: Int? = nil
    var action: (() -> Void)? = nil
}

struct ProfileSections: Identifiable {
    let id = UUID()
    let title: String
    let items: [ProfileMenuItem]
}
