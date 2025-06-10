import SwiftUI

@main
struct ControlGlucosaApp: App {
    @StateObject private var meals = Meals()
    @StateObject private var userProfiles = UserProfiles()
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environmentObject(meals)
                .environmentObject(userProfiles)
                .environmentObject(appState)
        }
    }
}

struct ContentRootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        switch appState.currentScreen {
        case .welcome:
            WelcomeView()
        case .userSetup:
            UserSetupView()
        case .main:
            MainTabView()
        }
    }
}