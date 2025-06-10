import Foundation
import SwiftUI

// MARK: - Core Types (ÚNICO)

enum MealType: String, CaseIterable, Codable, Identifiable {
    case breakfast = "Desayuno"
    case lunch = "Almuerzo"
    case dinner = "Cena"
    case snack = "Snack"
    
    var id: String { rawValue }
    
    var displayName: String {
        return rawValue
    }
    
    var emoji: String {
        switch self {
        case .breakfast: return "🌅"
        case .lunch: return "☀️"
        case .dinner: return "🌙"
        case .snack: return "🍎"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .breakfast: return "sun.rise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        }
    }
}

enum GlycemicIndex: String, CaseIterable, Codable, Identifiable {
    case low = "bajo"
    case medium = "medio"
    case high = "alto"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .low: return "Bajo"
        case .medium: return "Medio"
        case .high: return "Alto"
        }
    }
    
    var range: ClosedRange<Int> {
        switch self {
        case .low: return 0...55
        case .medium: return 56...69
        case .high: return 70...100
        }
    }
    
    var numericRange: String {
        switch self {
        case .low: return "≤ 55"
        case .medium: return "56-69"
        case .high: return "≥ 70"
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Absorción lenta de glucosa"
        case .medium: return "Absorción moderada de glucosa"
        case .high: return "Absorción rápida de glucosa"
        }
    }
}

// MARK: - Core Data Structures

struct UserProfile: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var age: Int
    var diabetesType: String
    var diagnosisYear: String
    var hasInsurance: Bool
    var preferredLanguage: String
    var preferredUnits: String
    var notificationsEnabled: Bool
    var weight: Double
    var height: Double
    
    init(name: String, age: Int, diabetesType: String = "", diagnosisYear: String = "", 
         hasInsurance: Bool = false, preferredLanguage: String = "Español", 
         preferredUnits: String = "mg/dL", notificationsEnabled: Bool = true,
         weight: Double = 70.0, height: Double = 170.0) {
        self.name = name
        self.age = age
        self.diabetesType = diabetesType
        self.diagnosisYear = diagnosisYear
        self.hasInsurance = hasInsurance
        self.preferredLanguage = preferredLanguage
        self.preferredUnits = preferredUnits
        self.notificationsEnabled = notificationsEnabled
        self.weight = weight
        self.height = height
    }
}