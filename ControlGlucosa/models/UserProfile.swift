// MARK: - Health-related models
// Archivo: UserProfile.swift

import Foundation

// Health-related enums that could be useful for future features
enum HealthGoal: String, CaseIterable, Codable {
    case weightLoss = "Pérdida de Peso"
    case weightGain = "Aumento de Peso"
    case muscleGain = "Ganancia Muscular"
    case glucoseControl = "Control Glucémico"
    case generalHealth = "Salud General"
}

struct GlucoseRange: Codable {
    let min: Double
    let max: Double
    
    static let normal = GlucoseRange(min: 70, max: 140)
    static let prediabetic = GlucoseRange(min: 70, max: 125)
    static let diabetic = GlucoseRange(min: 80, max: 180)
}