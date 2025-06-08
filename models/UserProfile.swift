import Foundation
import SwiftUI

struct UserProfile: Identifiable, Codable {
    var id = UUID()
    var name: String = ""
    var age: Int = 0
    var diabetesType: String = ""
    var diagnosisYear: String = ""
    var hasInsurance: Bool = false
    var preferredLanguage: String = "Español"
    var preferredUnits: String = "mg/dL"
    var notificationsEnabled: Bool = true
    
    init(name: String = "", age: Int = 0, diabetesType: String = "", diagnosisYear: String = "", hasInsurance: Bool = false, preferredLanguage: String = "Español", preferredUnits: String = "mg/dL", notificationsEnabled: Bool = true) {
        self.name = name
        self.age = age
        self.diabetesType = diabetesType
        self.diagnosisYear = diagnosisYear
        self.hasInsurance = hasInsurance
        self.preferredLanguage = preferredLanguage
        self.preferredUnits = preferredUnits
        self.notificationsEnabled = notificationsEnabled
    }
}

class UserProfiles: ObservableObject {
    @Published var currentProfile = UserProfile()
    @Published var profiles: [UserProfile] = []
    @Published var isProfileSetup = false
    
    private let saveKey = "savedUserProfile"
    private let setupKey = "profileSetupComplete"
    
    init() {
        loadProfile()
        loadSetupStatus()
    }
    
    func updateProfile(_ profile: UserProfile) {
        currentProfile = profile
        isProfileSetup = true
        saveProfile()
        saveSetupStatus()
    }
    
    func resetProfile() {
        currentProfile = UserProfile()
        isProfileSetup = false
        UserDefaults.standard.removeObject(forKey: saveKey)
        UserDefaults.standard.removeObject(forKey: setupKey)
    }
    
    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(currentProfile) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentProfile = decoded
        }
    }
    
    private func saveSetupStatus() {
        UserDefaults.standard.set(isProfileSetup, forKey: setupKey)
    }
    
    private func loadSetupStatus() {
        isProfileSetup = UserDefaults.standard.bool(forKey: setupKey)
    }
}
