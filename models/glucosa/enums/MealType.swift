// MARK: - MealType.swift
// Archivo: MealType.swift

import Foundation

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