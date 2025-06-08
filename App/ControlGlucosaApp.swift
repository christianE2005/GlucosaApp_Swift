//
//  ControlGlucosaApp.swift
//  ControlGlucosa
//
//  Created by Alumno on 07/06/25.
//

import SwiftUI
import Combine
import Foundation

@main
struct ControlGlucosaApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var userProfiles = UserProfiles()
    @StateObject private var meals = Meals()
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch appState.currentScreen {
                case .welcome:
                    WelcomeView()
                case .userSetup:
                    UserSetupView()
                case .main:
                    ContentView()
                }
            }
            .environmentObject(appState)
            .environmentObject(userProfiles)
            .environmentObject(meals)
        }
    }
}

// MARK: - App State Manager
class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .welcome
    
    func navigateToUserSetup() {
        currentScreen = .userSetup
    }
    
    func navigateToMain() {
        currentScreen = .main
    }
}

enum AppScreen {
    case welcome
    case userSetup
    case main
}