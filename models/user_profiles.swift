//
//  user_profiles.swift
//  ControlGlucosa
//
//  Created by Alumno on 07/06/25.
//

import SwiftUI

struct UserProfile: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String = ""
    // Add other user profile properties as needed
}



class UserProfiles: ObservableObject {
    @Published var currentProfile: UserProfile
    @Published var profiles: [UserProfile]
    
    private let saveKey = "savedUserProfiles"
    
    init() {
        self.currentProfile = UserProfile()
        self.profiles = []
        loadProfiles()
    }
    
    func saveProfile(_ profile: UserProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        saveProfiles()
    }
    
    func deleteProfile(_ profile: UserProfile) {
        profiles.removeAll(where: { $0.id == profile.id })
        saveProfiles()
    }
    
    func setCurrentProfile(_ profile: UserProfile) {
        currentProfile = profile
    }
    
    private func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([UserProfile].self, from: data) {
            profiles = decoded
            if !profiles.isEmpty {
                currentProfile = profiles[0]
            }
        }
    }
}