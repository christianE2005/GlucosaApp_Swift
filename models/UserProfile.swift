// MARK: - UserProfile.swift
// Archivo: UserProfile.swift

import Foundation

struct UserProfile: Identifiable, Codable {
    let id = UUID()
    var name: String
    var age: Int
    var weight: Double
    var height: Double
    var activityLevel: ActivityLevel
    var healthGoals: [HealthGoal]
    var diabetesType: DiabetesType?
    var targetGlucoseRange: GlucoseRange
    var dailyCalorieTarget: Double?
    var dailyCarbTarget: Double?
    
    enum ActivityLevel: String, CaseIterable, Codable {
        case sedentary = "Sedentario"
        case lightlyActive = "Ligeramente Activo"
        case moderatelyActive = "Moderadamente Activo"
        case veryActive = "Muy Activo"
        case extraActive = "Extremadamente Activo"
    }
    
    enum HealthGoal: String, CaseIterable, Codable {
        case weightLoss = "Pérdida de Peso"
        case weightGain = "Aumento de Peso"
        case muscleGain = "Ganancia Muscular"
        case glucoseControl = "Control de Glucosa"
        case generalHealth = "Salud General"
    }
    
    enum DiabetesType: String, CaseIterable, Codable {
        case type1 = "Tipo 1"
        case type2 = "Tipo 2"
        case gestational = "Gestacional"
        case prediabetes = "Prediabetes"
    }
    
    struct GlucoseRange: Codable {
        let min: Double
        let max: Double
        
        static let normal = GlucoseRange(min: 70, max: 140)
        static let prediabetic = GlucoseRange(min: 70, max: 125)
        static let diabetic = GlucoseRange(min: 80, max: 180)
    }
}