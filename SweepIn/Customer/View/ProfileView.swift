//
//  ProfileView.swift
//  SweepIn
//
//  Created by apple on 27/04/26.
//
import SwiftUI
struct ProfileView: View {
    
    @EnvironmentObject private var navigationManager: Router
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSignOutAlert = false
    
    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.97, blue: 1.0)
                .ignoresSafeArea()
            
            VStack(spacing: -52) {
                headerView
                contentView
            }
        }
        .alert("Sign out?", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                sessionManager.logout()
                navigationManager.replace(with: .Wellcome)
            }
        } message: {
            Text("Will you really sign out of this application?")
        }
    }
}

// - Header

private extension ProfileView {
    
    var headerView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.95),
                    Color.blue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 200, height: 200)
                .offset(x: -150, y: 100)
            
            VStack(spacing: 24) {
//                topBar
                
                VStack(spacing: 10) {
                    avatar
                    
                    Text(viewModel.userName)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(viewModel.email)
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.75))
                }
                
                statsCard
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 30)
        }
        .frame(height:400)
        .clipShape(
            RoundedRectangle(cornerRadius: 42)
        )
        .ignoresSafeArea(edges: .all)
    }
    
//    var topBar: some View {
//        HStack (spacing:10){
//            Button(action: viewModel.editProfile) {
//                Text("Edit")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 24)
//                    .padding(.vertical, 12)
//                    .background(.white.opacity(0.15))
//                    .clipShape(Capsule())
//            }
//        }
//    }
    
    var avatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(.white.opacity(0.15))
                .frame(width: 90, height:80)
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(.white.opacity(0.18), lineWidth: 2)
                }
            
            Text(viewModel.initials)
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    var statsCard: some View {
        HStack(spacing: 0) {
            ForEach(Array(viewModel.stats.enumerated()), id: \.element.id) { index, stat in
                statItem(stat)
                
                if index < viewModel.stats.count - 1 {
                    Divider()
                        .background(.white.opacity(0.2))
                }
            }
        }
        .frame(height: 80)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        }
    }
    
    func statItem(_ stat: ProfileStat) -> some View {
        VStack(spacing: 6) {
            Text(stat.value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text(stat.title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Content

private extension ProfileView {
    
    var contentView: some View {
        ScrollView {
            VStack(spacing: 10) {
                liveUpdatesSection
                
                ForEach(viewModel.sections) { section in
                    sectionView(section)
                }
                
                signOutButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)
            .padding(.bottom, 30)
            .background(Color.white)
        }
    }

    var liveUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let notification = viewModel.latestNotification {
                VStack(alignment: .leading, spacing: 10) {
                    Text("LATEST NOTIFICATION")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .tracking(1.5)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: notification.isRead ? "bell" : "bell.badge.fill")
                            .foregroundColor(.blue)

                        Text(notification.message)
                            .font(.subheadline)
                            .foregroundColor(.black)

                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("LIVE BOOKING STATUS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .tracking(1.5)

                if let booking = viewModel.latestBooking {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(booking.serviceName)
                                    .font(.headline)
                                    .foregroundColor(.black)

                                Text(booking.scheduleSummary)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Text(booking.status.rawValue)
                                .font(.caption.bold())
                                .foregroundColor(booking.status.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(booking.status.backgroundColor)
                                .clipShape(Capsule())
                        }

                        Text(booking.customerStatusMessage)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.blue)

                        Text("Total payable: ₹\(booking.totalAmount)")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                } else {
                    Text("Your active booking will appear here after you book a service.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    func sectionView(_ section: ProfileSection) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(section.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .tracking(1.5)
            
            VStack(spacing: 0) {
                ForEach(section.items) { item in
                    menuRow(item)
                    
                    if item.id != section.items.last?.id {
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
        }
    }
    
    func menuRow(_ item: ProfileMenuItem) -> some View {
        Group {
            if let action = item.action {
                Button(action: action) {
                    rowContent(for: item)
                }
            } else {
                rowContent(for: item)
            }
        }
    }

    @ViewBuilder
    func rowContent(for item: ProfileMenuItem) -> some View {
            HStack(spacing: 16) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundColor(item.tint)
                    .frame(width: 46, height: 46)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if let badge = item.badge {
                    Text("\(badge)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                
                if item.action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.vertical, 18)
    }
    
    var signOutButton: some View {
        Button {
            showingSignOutAlert = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "arrow.right")
                    .foregroundColor(.red)
                
                Text("Sign out")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.red)
                
                Spacer()
            }
            .padding(.vertical, 20)
        }
    }
}



#Preview {
    ProfileView()
        .environmentObject(Router())
        .environmentObject(SessionManager())
}
