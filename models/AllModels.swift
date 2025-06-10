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

struct UserProfile: Identifiable, Codable {
    let id = UUID()
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

// MARK: - Supporting Types

enum DiabetesType: String, CaseIterable, Identifiable {
    case type1 = "Tipo 1"
    case type2 = "Tipo 2"
    case gestational = "Gestacional"
    case prediabetes = "Prediabetes"
    
    var id: String { rawValue }
}

enum TimeRange: String, CaseIterable {
    case day = "Hoy"
    case week = "Semana"
    case month = "Mes"
    case year = "Año"
    
    var displayName: String { rawValue }
}

enum ChartType: String, CaseIterable, Identifiable {
    case glucose = "Glucosa"
    case carbs = "Carbohidratos"
    case calories = "Calorías"
    case proteins = "Proteínas"
    case fats = "Grasas"
    case fiber = "Fibra"
    case glycemic = "Impacto Glucémico"
    case categories = "Categorías"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .glucose: return "drop.fill"
        case .carbs: return "leaf.fill"
        case .calories: return "flame.fill"
        case .proteins: return "figure.strengthtraining.traditional"
        case .fats: return "drop.circle.fill"
        case .fiber: return "leaf.circle.fill"
        case .glycemic: return "chart.line.uptrend.xyaxis"
        case .categories: return "chart.pie.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .glucose: return .red
        case .carbs: return .orange
        case .calories: return .blue
        case .proteins: return .green
        case .fats: return .purple
        case .fiber: return .brown
        case .glycemic: return .pink
        case .categories: return .cyan
        }
    }
}

struct Recommendation {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Observable Objects

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
        do {
            let encoded = try JSONEncoder().encode(meals)
            UserDefaults.standard.set(encoded, forKey: "SavedMeals")
        } catch {
            print("Error saving meals: \(error.localizedDescription)")
        }
    }
    
    init() {
        loadMeals()
    }
    
    private func loadMeals() {
        guard let data = UserDefaults.standard.data(forKey: "SavedMeals") else {
            loadSampleData()
            return
        }
        
        do {
            meals = try JSONDecoder().decode([Meal].self, from: data)
        } catch {
            print("Error loading meals: \(error.localizedDescription)")
            loadSampleData()
        }
    }
    
    private func loadSampleData() {
        let sampleMeals = [
            Meal(
                name: "🧠 Desayuno con avena",
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
                glycemicIndex: .medium,
                isAIAnalyzed: true
            ),
            Meal(
                name: "🧠 Almuerzo saludable",
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
                glycemicIndex: .low,
                isAIAnalyzed: true
            )
        ]
        meals = sampleMeals
    }
}

class UserProfiles: ObservableObject {
    @Published var currentProfile: UserProfile = UserProfile(
        name: "Usuario Demo",
        age: 30,
        diabetesType: "Tipo 2",
        diagnosisYear: "2020",
        notificationsEnabled: true
    )
    
    func updateProfile(_ profile: UserProfile) {
        currentProfile = profile
        saveProfile()
    }
    
    func resetProfile() {
        currentProfile = UserProfile(name: "", age: 0)
        UserDefaults.standard.removeObject(forKey: "CurrentProfile")
    }
    
    private func saveProfile() {
        do {
            let encoded = try JSONEncoder().encode(currentProfile)
            UserDefaults.standard.set(encoded, forKey: "CurrentProfile")
        } catch {
            print("Error saving profile: \(error.localizedDescription)")
        }
    }
    
    init() {
        loadProfile()
    }
    
    private func loadProfile() {
        guard let data = UserDefaults.standard.data(forKey: "CurrentProfile") else { return }
        
        do {
            currentProfile = try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            print("Error loading profile: \(error.localizedDescription)")
        }
    }
}

class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .welcome
    
    enum AppScreen {
        case welcome
        case userSetup
        case main
    }
    
    func navigateToUserSetup() {
        currentScreen = .userSetup
    }
    
    func navigateToMain() {
        currentScreen = .main
    }
    
    func resetToWelcome() {
        currentScreen = .welcome
    }
}