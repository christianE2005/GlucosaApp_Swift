import Foundation
import SwiftUI

// MARK: - Core Data Models

class Meals: ObservableObject {
    @Published var meals: [Meal] = []
    
    func addMeal(_ meal: Meal) {
        meals.append(meal)
        saveMeals()
    }
    
    func removeMeal(withId id: UUID) {
        meals.removeAll { $0.id == id }
        saveMeals()
    }
    
    private func saveMeals() {
        // Implementar persistencia si es necesario
        print("Guardando \(meals.count) comidas...")
    }
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        // Datos de ejemplo para testing
        let sampleMeals = [
            Meal(
                name: "Desayuno con avena",
                type: .breakfast,
                portions: ["1 taza avena", "1 plátano"],
                timestamp: Date().addingTimeInterval(-3600),
                totalCarbs: 45.0,
                glucoseLevel: 95.0,
                date: Date(),
                calories: 320,
                proteins: 12,
                fats: 6,
                fiber: 8,
                isAIAnalyzed: true
            ),
            Meal(
                name: "Almuerzo saludable",
                type: .lunch,
                portions: ["Ensalada", "Pollo a la plancha"],
                timestamp: Date().addingTimeInterval(-7200),
                totalCarbs: 25.0,
                glucoseLevel: 88.0,
                date: Date(),
                calories: 450,
                proteins: 35,
                fats: 15,
                fiber: 12,
                isAIAnalyzed: true
            )
        ]
        meals = sampleMeals
    }
}

class UserProfiles: ObservableObject {
    @Published var currentProfile: UserProfile?
    
    init() {
        // Perfil de ejemplo
        currentProfile = UserProfile(
            name: "Usuario Demo",
            age: 30,
            weight: 70.0,
            height: 170.0,
            activityLevel: "Moderado",
            healthGoals: ["Control de glucosa", "Pérdida de peso"]
        )
    }
}

class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .main
    
    enum AppScreen {
        case welcome
        case main
        case onboarding
    }
}

// MARK: - Data Structures

struct Meal: Identifiable, Codable {
    let id = UUID()
    var name: String
    var type: MealType
    var portions: [String]
    var timestamp: Date
    var glucoseReadingBefore: Double?
    var glucoseReadingAfter: Double?
    var totalCarbs: Double?
    var glucoseLevel: Double?
    var date: Date
    
    // Datos nutricionales del análisis IA
    var calories: Double?
    var proteins: Double?
    var fats: Double?
    var fiber: Double?
    var sugars: Double?
    var sodium: Double?
    var glycemicIndex: GlycemicIndex?
    var portionSizeGrams: Double?
    var isAIAnalyzed: Bool
    
    init(name: String, type: MealType, portions: [String], timestamp: Date = Date(),
         glucoseReadingBefore: Double? = nil, glucoseReadingAfter: Double? = nil,
         totalCarbs: Double? = nil, glucoseLevel: Double? = nil, date: Date = Date(),
         calories: Double? = nil, proteins: Double? = nil, fats: Double? = nil,
         fiber: Double? = nil, sugars: Double? = nil, sodium: Double? = nil,
         glycemicIndex: GlycemicIndex? = nil, portionSizeGrams: Double? = nil,
         isAIAnalyzed: Bool = false) {
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
}

enum MealType: String, CaseIterable, Codable {
    case breakfast = "Desayuno"
    case lunch = "Almuerzo"
    case dinner = "Cena"
    case snack = "Snack"
    
    var displayName: String {
        return self.rawValue
    }
}

enum GlycemicIndex: String, Codable, CaseIterable {
    case low = "bajo"
    case medium = "medio"
    case high = "alto"
}

struct UserProfile: Identifiable, Codable {
    let id = UUID()
    let name: String
    let age: Int
    let weight: Double
    let height: Double
    let activityLevel: String
    let healthGoals: [String]
}