//
//  MainTabView.swift
//  SweepIn
//
//  Created by apple on 26/04/26.
//

import SwiftUI

//  Main Tab View
struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @StateObject private var bookingViewModel = BookCleaningViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {

            HomeView(selectedTab: $selectedTab, bookingViewModel: bookingViewModel)
                .tabItem { Label("Home",     systemImage: "house.fill") }
                .tag(0)

            BookCleaningView(viewModel: bookingViewModel, selectedTab: $selectedTab)
                .tabItem { Label("Bookings", systemImage: "calendar") }
                .tag(1)

            ProfileView()
                .tabItem { Label("Profile",  systemImage: "person.fill") }
                .tag(2)
        }
        .accentColor(Color.sky)
    }
}


#Preview {
    MainTabView()
        .environmentObject(Router())
}
