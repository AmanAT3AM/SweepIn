//
//  HomeView.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//

import SwiftUI
struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject var bookingViewModel: BookCleaningViewModel
    @Binding var selectedTab: Int

    init(selectedTab: Binding<Int>, bookingViewModel: BookCleaningViewModel) {
        self._selectedTab = selectedTab
        self.bookingViewModel = bookingViewModel
    }

    var body: some View {
        ZStack {
            Color.appBG
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderSectionView(
                    viewModel: viewModel,
                    bookingViewModel: bookingViewModel,
                    selectedTab: $selectedTab
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        FilterChipsView(viewModel: viewModel)
                        ServicesSectionView(viewModel: viewModel) { service in
                            bookingViewModel.selectService(service)
                            selectedTab = 1
                        }
                        TopCleanersSectionView(viewModel: viewModel)
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 10)
                }
            }
        }
    }
}

//  - Header Section
struct HeaderSectionView: View {

    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var bookingViewModel: BookCleaningViewModel
    @Binding var selectedTab: Int

    var body: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient.headerBG)
                .ignoresSafeArea(edges: .top)
                .frame(height: 140)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.greeting)
                            .font(CleanlyFont.jakarta(14))
                            .foregroundColor(.white.opacity(0.85))

                        Text(viewModel.userName)
                            .font(CleanlyFont.sora(28, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    notificationButton
                }
                .padding(.horizontal, 24)
            }
        }
    }

    var notificationButton: some View {
        let unreadCount = bookingViewModel.customerNotifications.filter { !$0.isRead }.count

        return Button {
            selectedTab = 2
        } label: {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: "bell.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 33))

                if unreadCount > 0 {
                    Text(unreadCount > 99 ? "99+" : "\(unreadCount)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .frame(minWidth: 18, minHeight: 18)
                        .padding(.horizontal, unreadCount > 9 ? 4 : 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: 10, y: -10)
                }
            }
        }
    }
}

// - Filter Chips
struct FilterChipsView: View {

    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ServiceFilter.allCases, id: \.self) { filter in
                    Button {
                        viewModel.selectFilter(filter)
                    } label: {
                        Text(filter.rawValue)
                            .font(CleanlyFont.jakarta(14, weight: viewModel.selectedFilter == filter ? .semibold : .regular))
                            .foregroundColor(viewModel.selectedFilter == filter ? .white : Color.ink)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(
                                viewModel.selectedFilter == filter
                                ? Color.sky
                                : Color.white
                            )
                            .clipShape(Capsule())
                            .shadowSm()
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

//  - Services Section
struct ServicesSectionView: View {

    @ObservedObject var viewModel: HomeViewModel
    let onSelectService: (CleaningService) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Services")
                    .font(CleanlyFont.sora(20, weight: .bold))
                    .foregroundColor(Color.ink)

                Spacer()

                Button("See all") {
                    viewModel.seeAllServices()
                }
                .font(CleanlyFont.jakarta(14, weight: .semibold))
                .foregroundColor(Color.sky)
            }
            .padding(.horizontal, 24)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 14
            ) {
                ForEach(viewModel.filteredServices) { service in
                    ServiceCardView(service: service) {
                        onSelectService(service)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

//  - Service Card
struct ServiceCardView: View {

    let service: CleaningService
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(service.accentColor)
                            .frame(width: 48, height: 48)

                        Image(systemName: service.icon)
                            .font(.system(size: 22))
                            .foregroundColor(service.isPopular ? Color.sky : Color.ink2)
                    }

                    Text(service.name)
                        .font(CleanlyFont.jakarta(15, weight: .semibold))
                        .foregroundColor(Color.ink)

                    Text(service.price)
                        .font(CleanlyFont.jakarta(13))
                        .foregroundColor(Color.stone)

                    Text(service.duration)
                        .font(CleanlyFont.jakarta(12))
                        .foregroundColor(Color.stone2)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gold)

                        Text("\(service.rating) (\(service.reviews))")
                            .font(CleanlyFont.jakarta(12))
                            .foregroundColor(Color.stone2)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(service.isPopular ? Color.sky4 : Color.clear, lineWidth: 1.5)
                )
                .shadowSm()

                if service.isPopular {
                    Text("Popular")
                        .font(CleanlyFont.jakarta(11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.sky)
                        .clipShape(Capsule())
                        .padding(10)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

//  - Top Cleaners Section
struct TopCleanersSectionView: View {

    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Top cleaners")
                    .font(CleanlyFont.sora(20, weight: .bold))
                    .foregroundColor(Color.ink)

                Spacer()

                Button("See all") {
                    viewModel.seeAllCleaners()
                }
                .font(CleanlyFont.jakarta(14, weight: .semibold))
                .foregroundColor(Color.sky)
            }
            .padding(.horizontal, 24)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 14
            ) {
                ForEach(viewModel.topCleaners) { cleaner in
                    CleanerCardView(cleaner: cleaner)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

//  - Cleaner Card
struct CleanerCardView: View {

    let cleaner: TopCleaner

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(cleaner.avatarColor.opacity(0.15))
                    .frame(width: 52, height: 52)

                Text(cleaner.initials)
                    .font(CleanlyFont.sora(18, weight: .bold))
                    .foregroundColor(cleaner.avatarColor)
            }

            Text(cleaner.name)
                .font(CleanlyFont.jakarta(15, weight: .semibold))
                .foregroundColor(Color.ink)

            Text(cleaner.specialty)
                .font(CleanlyFont.jakarta(12))
                .foregroundColor(Color.stone)
                .lineLimit(1)

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color.gold)

                Text(cleaner.rating)
                    .font(CleanlyFont.jakarta(13, weight: .semibold))
                    .foregroundColor(Color.ink)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadowSm()
    }
}

//  - Preview
#Preview {
    MainTabView()
}
