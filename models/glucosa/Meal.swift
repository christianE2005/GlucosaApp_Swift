// MARK: - Meal.swift
// Archivo: Meal.swift

import Foundation

struct Meal: Identifiable, Codable {
    var id = UUID()
    var name: String
    var type: MealType
    var portions: [String]
    var timestamp: Date
    var glucoseReadingBefore: Double?
    var glucoseReadingAfter: Double?
    var totalCarbs: Double?
    var glucoseLevel: Double?
    var date: Date
    
    // MARK: - Datos nutricionales analizados por IA
    var calories: Double?
    var proteins: Double?
    var fats: Double?
    var fiber: Double?
    var sugars: Double?
    var sodium: Double?
    var glycemicIndex: GlycemicIndex?
    var portionSizeGrams: Double?
    var isAIAnalyzed: Bool
    
    // MARK: - Inicializador completo
    init(
        name: String,
        type: MealType = .breakfast,
        portions: [String] = [],
        timestamp: Date = Date(),
        glucoseReadingBefore: Double? = nil,
        glucoseReadingAfter: Double? = nil,
        totalCarbs: Double? = nil,
        glucoseLevel: Double? = nil,
        date: Date = Date(),
        calories: Double? = nil,
        proteins: Double? = nil,
        fats: Double? = nil,
        fiber: Double? = nil,
        sugars: Double? = nil,
        sodium: Double? = nil,
        glycemicIndex: GlycemicIndex? = nil,
        portionSizeGrams: Double? = nil,
        isAIAnalyzed: Bool = false
    ) {
        self.name = name
        self.type = type
        self.portions = portions
        self.timestamp = timestamp
        self.glucoseReadingBefore = glucoseReadingBefore
        self.glucoseReadingAfter = glucoseReadingAfter
        self.totalCarbs = totalCarbs
        self.glucoseLevel = glucoseLevel
        self.date = date
        self.calories = calories
        self.proteins = proteins
        self.fats = fats
        self.fiber = fiber
        self.sugars = sugars
        self.sodium = sodium
        self.glycemicIndex = glycemicIndex
        self.portionSizeGrams = portionSizeGrams
        self.isAIAnalyzed = isAIAnalyzed
    }
    
    // MARK: - Codable Implementation (Explicit para evitar errores)
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case portions
        case timestamp
        case glucoseReadingBefore
        case glucoseReadingAfter
        case totalCarbs
        case glucoseLevel
        case date
        case calories
        case proteins
        case fats
        case fiber
        case sugars
        case sodium
        case glycemicIndex
        case portionSizeGrams
        case isAIAnalyzed
    }
    
    // MARK: - Decoder personalizado para manejar compatibilidad
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(MealType.self, forKey: .type)
        portions = try container.decodeIfPresent([String].self, forKey: .portions) ?? []
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        glucoseReadingBefore = try container.decodeIfPresent(Double.self, forKey: .glucoseReadingBefore)
        glucoseReadingAfter = try container.decodeIfPresent(Double.self, forKey: .glucoseReadingAfter)
        totalCarbs = try container.decodeIfPresent(Double.self, forKey: .totalCarbs)
        glucoseLevel = try container.decodeIfPresent(Double.self, forKey: .glucoseLevel)
        date = try container.decode(Date.self, forKey: .date)
        calories = try container.decodeIfPresent(Double.self, forKey: .calories)
        proteins = try container.decodeIfPresent(Double.self, forKey: .proteins)
        fats = try container.decodeIfPresent(Double.self, forKey: .fats)
        fiber = try container.decodeIfPresent(Double.self, forKey: .fiber)
        sugars = try container.decodeIfPresent(Double.self, forKey: .sugars)
        sodium = try container.decodeIfPresent(Double.self, forKey: .sodium)
        glycemicIndex = try container.decodeIfPresent(GlycemicIndex.self, forKey: .glycemicIndex)
        portionSizeGrams = try container.decodeIfPresent(Double.self, forKey: .portionSizeGrams)
        isAIAnalyzed = try container.decodeIfPresent(Bool.self, forKey: .isAIAnalyzed) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(portions, forKey: .portions)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(glucoseReadingBefore, forKey: .glucoseReadingBefore)
        try container.encodeIfPresent(glucoseReadingAfter, forKey: .glucoseReadingAfter)
        try container.encodeIfPresent(totalCarbs, forKey: .totalCarbs)
        try container.encodeIfPresent(glucoseLevel, forKey: .glucoseLevel)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(calories, forKey: .calories)
        try container.encodeIfPresent(proteins, forKey: .proteins)
        try container.encodeIfPresent(fats, forKey: .fats)
        try container.encodeIfPresent(fiber, forKey: .fiber)
        try container.encodeIfPresent(sugars, forKey: .sugars)
        try container.encodeIfPresent(sodium, forKey: .sodium)
        try container.encodeIfPresent(glycemicIndex, forKey: .glycemicIndex)
        try container.encodeIfPresent(portionSizeGrams, forKey: .portionSizeGrams)
        try container.encode(isAIAnalyzed, forKey: .isAIAnalyzed)
    }
}

// MARK: - Extensiones para Meal
extension Meal {
    /// Calcula la diferencia de glucosa (después - antes)
    var glucoseDifference: Double? {
        guard let before = glucoseReadingBefore,
              let after = glucoseReadingAfter else { return nil }
        return after - before
    }
    
    /// Determina si la lectura de glucosa está en rango normal
    var isGlucoseInNormalRange: Bool? {
        guard let glucose = glucoseLevel else { return nil }
        return glucose >= 70 && glucose <= 140
    }
    
    /// Calcula el total de macronutrientes (carbohidratos + proteínas + grasas)
    var totalMacronutrients: Double? {
        guard let carbs = totalCarbs,
              let proteins = proteins,
              let fats = fats else { return nil }
        return carbs + proteins + fats
    }
    
    /// Calcula el porcentaje de carbohidratos del total de macronutrientes
    var carbsPercentage: Double? {
        guard let carbs = totalCarbs,
              let total = totalMacronutrients,
              total > 0 else { return nil }
        return (carbs / total) * 100
    }
    
    /// Determina si la comida es alta en fibra (>5g)
    var isHighFiber: Bool {
        guard let fiber = fiber else { return false }
        return fiber > 5.0
    }
    
    /// Categoriza la comida según su contenido calórico
    var calorieCategory: String? {
        guard let calories = calories else { return nil }
        switch calories {
        case 0...150:
            return "Ligera"
        case 151...300:
            return "Moderada"
        case 301...500:
            return "Sustanciosa"
        default:
            return "Alta en calorías"
        }
    }
    
    /// Genera un resumen nutricional de la comida
    var nutritionalSummary: String {
        var summary = "📊 Resumen Nutricional:\n"
        
        if let calories = calories {
            summary += "• Calorías: \(Int(calories)) kcal\n"
        }
        
        if let carbs = totalCarbs {
            summary += "• Carbohidratos: \(Int(carbs))g\n"
        }
        
        if let proteins = proteins {
            summary += "• Proteínas: \(Int(proteins))g\n"
        }
        
        if let fats = fats {
            summary += "• Grasas: \(Int(fats))g\n"
        }
        
        if let fiber = fiber {
            summary += "• Fibra: \(Int(fiber))g\n"
        }
        
        if let gi = glycemicIndex {
            summary += "• Índice Glucémico: \(gi.displayName)\n"
        }
        
        if let glucose = glucoseLevel {
            summary += "• Glucosa: \(Int(glucose)) mg/dL\n"
        }
        
        return summary
    }
}
