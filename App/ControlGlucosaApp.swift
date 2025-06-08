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
                    MainTabView()  // ← CAMBIO AQUÍ: Usar MainTabView en lugar de ContentView
                }
            }
            .environmentObject(appState)
            .environmentObject(userProfiles)
            .environmentObject(meals)
            .onAppear {
                // Determinar la pantalla inicial basado en el estado del usuario
                if userProfiles.isProfileSetup && !userProfiles.currentProfile.name.isEmpty {
                    appState.currentScreen = .main
                } else {
                    appState.currentScreen = .welcome
                }
            }
        }
    }
}

// MARK: - App State Manager
class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .welcome
    
    func navigateToWelcome() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentScreen = .welcome
        }
    }
    
    func navigateToUserSetup() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentScreen = .userSetup
        }
    }
    
    func navigateToMain() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentScreen = .main
        }
    }
    
    func resetToWelcome() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentScreen = .welcome
        }
    }
}

enum AppScreen {
    case welcome
    case userSetup
    case main
}
