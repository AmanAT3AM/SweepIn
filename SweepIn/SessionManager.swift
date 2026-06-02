//
//  SessionManager.swift
//  SweepIn
//
//  Created by apple on 24/05/26.
//

import Combine
import FirebaseAuth
import Foundation

@MainActor
final class SessionManager: ObservableObject {

    @Published private(set) var userSession: FirebaseAuth.User?
    @Published private(set) var currentUser: User?
    @Published private(set) var isRestoringSession = true

    private var authService: AuthService?
    private var cancellables = Set<AnyCancellable>()
    private var didRestoreSession = false

    var isLoggedIn: Bool {
        userSession != nil
    }

    var launchDestination: Router.Destination {
        rootDestination ?? .Wellcome
    }

    var rootDestination: Router.Destination? {
        destination(for: currentUser?.role)
    }

    func restoreSession() async {
        guard !didRestoreSession else {
            isRestoringSession = false
            return
        }

        didRestoreSession = true
        let service = ensureAuthService()
        await service.loadCurrentUser()
        isRestoringSession = false
    }

    func logout() {
        ensureAuthService().logout()
    }

    private func ensureAuthService() -> AuthService {
        if let authService {
            return authService
        }

        let service = AuthService.shared
        authService = service
        bindAuthService(service)
        return service
    }

    private func bindAuthService(_ authService: AuthService) {
        authService.$userSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.userSession = session
            }
            .store(in: &cancellables)

        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
    }

    private func destination(for role: UserRole?) -> Router.Destination? {
        guard let role else { return nil }

        switch role {
        case .customer:
            return .mainTab
        case .provider:
            return .providerTab
        }
    }
}
