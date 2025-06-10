import SwiftUI

enum AppScreen {
    case welcome
    case userSetup
    case main
}

class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .welcome
    
    func navigateToUserSetup() {
        currentScreen = .userSetup
    }
    
    func navigateToMain() {
        currentScreen = .main
    }
    
    func resetToWelcome() {
        currentScreen = .welcome
    }
}
