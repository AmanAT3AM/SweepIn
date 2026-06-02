//
//  Profile.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

import Foundation
import SwiftUI

// - Model

struct ProfileStat: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct ProfileMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String
    let badge: Int?
    let tint: Color
    let action: (() -> Void)?

    init(title: String, subtitle: String? = nil, icon: String, badge: Int?, tint: Color, action: (() -> Void)?) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.badge = badge
        self.tint = tint
        self.action = action
    }
}

struct ProfileSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [ProfileMenuItem]
}
