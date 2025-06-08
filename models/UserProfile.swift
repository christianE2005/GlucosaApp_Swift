import Foundation

struct UserProfile: Identifiable, Codable {
    let id = UUID()
    var name: String = ""
    var age: Int = 0
    var diabetesType: String = ""
    var hasInsurance: Bool = false
    var preferredLanguage: String = "Español"
    
    init(name: String = "", age: Int = 0, diabetesType: String = "", hasInsurance: Bool = false, preferredLanguage: String = "Español") {
        self.name = name
        self.age = age
        self.diabetesType = diabetesType
        self.hasInsurance = hasInsurance
        self.preferredLanguage = preferredLanguage
    }
}

class UserProfiles: ObservableObject {
    @Published var currentProfile = UserProfile()
    
    func updateProfile(_ profile: UserProfile) {
        currentProfile = profile
    }
}