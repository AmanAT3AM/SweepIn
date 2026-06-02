//
//  NavigationManager.swift
//  SweepIn
//
//  Created by apple on 26/04/26.
//

import SwiftUI
import Combine

//  Navigation Manager

class Router: ObservableObject {

    @Published var path = NavigationPath()
    
    
    public enum Destination: Hashable {
        case Onboarding
        case Wellcome
//        case auth
        case Login
        case SignUp
        case ForgotPassword
        case mainTab
        case providerTab
    }

    func navigateToNext(screenName : Destination)  {
        path.append(screenName)
    }
    
    func navigatToBack(){
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func navigateToRoot() {
        guard !path.isEmpty else { return }
        path.removeLast(path.count)
    }
    
    func replace(with route: Destination) {
        path = NavigationPath()
        path.append(route)
    }
}
