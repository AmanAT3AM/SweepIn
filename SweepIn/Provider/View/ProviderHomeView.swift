
// ProviderHomeView
import Foundation
import SwiftUI

// - Provider Home View

struct ProviderHomeView: View {

    @StateObject private var viewModel = ProviderHomeViewModel()
    @StateObject private var bookingViewModel = ProviderBookingViewModel()

    var body: some View {
        ZStack {
                Color.appBG
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ProviderHeaderSectionView(
                    viewModel: viewModel,
                    bookingViewModel: bookingViewModel
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        ProviderServicesSectionView(viewModel: viewModel)
                        ProviderTopCleanersSectionView(viewModel: viewModel)
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 10)
                }
            }
        }
    }
}

//  - Header

struct ProviderHeaderSectionView: View {

    @ObservedObject var viewModel: ProviderHomeViewModel
    @ObservedObject var bookingViewModel: ProviderBookingViewModel

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
        let unreadCount = bookingViewModel.unreadNotificationCount

        return Button { } label: {
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

//  - Services Section

struct ProviderServicesSectionView: View {

    @ObservedObject var viewModel: ProviderHomeViewModel

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

            ProviderExpertiseEditorView(viewModel: viewModel)
                .padding(.horizontal, 24)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 14
            ) {
                ForEach(viewModel.services) { service in
                    ProviderServiceCardView(service: service)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

struct ProviderExpertiseEditorView: View {

    @ObservedObject var viewModel: ProviderHomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add your expertise")
                .font(CleanlyFont.jakarta(15, weight: .bold))
                .foregroundColor(.ink)

            HStack(spacing: 10) {
                TextField("Example: Deep clean, Kitchen clean", text: $viewModel.expertiseDraft)
                    .font(CleanlyFont.jakarta(14))
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Button("Add") {
                    viewModel.addExpertise()
                }
                .font(CleanlyFont.jakarta(14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 46)
                .background(Color.sky)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if !viewModel.providerExpertise.isEmpty {
                FlexibleChipView(items: viewModel.providerExpertise) { value in
                    viewModel.removeExpertise(value)
                }
            }

            if let expertiseMessage = viewModel.expertiseMessage {
                Text(expertiseMessage)
                    .font(CleanlyFont.jakarta(12))
                    .foregroundColor(.stone)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadowSm()
    }
}

struct FlexibleChipView: View {

    let items: [String]
    let onRemove: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack {
                    Text(item)
                        .font(CleanlyFont.jakarta(13, weight: .medium))
                        .foregroundColor(.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.sky.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()

                    Button {
                        onRemove(item)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

// MARK: - Service Card

struct ProviderServiceCardView: View {

    let service: ProviderService

    var body: some View {
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
}

// MARK: - Top Cleaners Section

struct ProviderTopCleanersSectionView: View {

    @ObservedObject var viewModel: ProviderHomeViewModel

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
                    ProviderCleanerCardView(cleaner: cleaner)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Cleaner Card

struct ProviderCleanerCardView: View {

    let cleaner: ProviderCleaner

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

// - Preview

#Preview {
    ProviderHomeView()
}
