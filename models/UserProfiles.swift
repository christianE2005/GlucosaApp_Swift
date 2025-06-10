import Foundation
import Combine

class UserProfiles: ObservableObject {
    @Published var currentProfile: UserProfile?
    @Published var profiles: [UserProfile] = []
    
    init() {
        loadFromUserDefaults()
    }
    
    func addProfile(_ profile: UserProfile) {
        profiles.append(profile)
        if currentProfile == nil {
            currentProfile = profile
        }
        saveToUserDefaults()
    }
    
    func updateCurrentProfile(_ profile: UserProfile) {
        currentProfile = profile
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        }
        saveToUserDefaults()
    }
    
    func setCurrentProfile(_ profile: UserProfile) {
        currentProfile = profile
        saveToUserDefaults()
    }
    
    private func saveToUserDefaults() {
        do {
            let encoded = try JSONEncoder().encode(profiles)
            UserDefaults.standard.set(encoded, forKey: "SavedProfiles")
            
            if let currentProfile = currentProfile {
                let currentEncoded = try JSONEncoder().encode(currentProfile)
                UserDefaults.standard.set(currentEncoded, forKey: "CurrentProfile")
            }
        } catch {
            print("Error saving profiles: \(error.localizedDescription)")
        }
    }
    
    private func loadFromUserDefaults() {
        // Cargar perfiles
        if let data = UserDefaults.standard.data(forKey: "SavedProfiles") {
            do {
                self.profiles = try JSONDecoder().decode([UserProfile].self, from: data)
            } catch {
                print("Error loading profiles: \(error.localizedDescription)")
                self.profiles = []
            }
        }
        
        // Cargar perfil actual
        if let data = UserDefaults.standard.data(forKey: "CurrentProfile") {
            do {
                self.currentProfile = try JSONDecoder().decode(UserProfile.self, from: data)
            } catch {
                print("Error loading current profile: \(error.localizedDescription)")
                self.currentProfile = profiles.first
            }
        }
    }
}