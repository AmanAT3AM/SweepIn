//
//  ProviderTabView.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

import SwiftUI

struct ProviderTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            ProviderHomeView()
                .tabItem { Label("Home",systemImage: "house.fill") }
                .tag(0)

            ProviderBookingView()
                .tabItem { Label("Bookings", systemImage: "calendar") }
                .tag(1)

            ProviderProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(2)
        }
        .accentColor(Color.sky)
    }
}

#Preview {
    ProviderTabView()
        .environmentObject(Router())
}
