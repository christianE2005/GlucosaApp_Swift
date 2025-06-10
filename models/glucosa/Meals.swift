import Foundation
import Combine

class Meals: ObservableObject {
    @Published var meals: [Meal] = []
    
    init() {
        loadFromUserDefaults()
    }
    
    // MARK: - Métodos para manipular las comidas
    
    func addMeal(_ meal: Meal) {
        meals.append(meal)
        sortMealsByDate()
        saveToUserDefaults()
    }
    
    func removeMeal(at indices: IndexSet) {
        meals.remove(atOffsets: indices)
        saveToUserDefaults()
    }
    
    func removeMeal(withId id: UUID) {
        meals.removeAll { $0.id == id }
        saveToUserDefaults()
    }
    
    func updateMeal(_ meal: Meal) {
        if let index = meals.firstIndex(where: { $0.id == meal.id }) {
            meals[index] = meal
            sortMealsByDate()
            saveToUserDefaults()
        }
    }
    
    private func sortMealsByDate() {
        meals.sort { $0.date > $1.date } // Más recientes primero
    }
    
    // MARK: - Métodos de consulta y filtrado
    
    func mealsForDate(_ date: Date) -> [Meal] {
        let calendar = Calendar.current
        return meals.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func mealsForDateRange(from startDate: Date, to endDate: Date) -> [Meal] {
        return meals.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    func mealsOfType(_ type: MealType) -> [Meal] {
        return meals.filter { $0.type == type }
    }
    
    func aiAnalyzedMeals() -> [Meal] {
        return meals.filter { $0.isAIAnalyzed }
    }
    
    func mealsWithGlucoseReadings() -> [Meal] {
        return meals.filter { $0.glucoseLevel != nil }
    }
    
    // MARK: - Métricas y estadísticas
    
    var averageGlucose: Double? {
        let glucoseReadings = meals.compactMap { $0.glucoseLevel }
        guard !glucoseReadings.isEmpty else { return nil }
        return glucoseReadings.reduce(0, +) / Double(glucoseReadings.count)
    }
    
    var totalCarbohydrates: Double {
        return meals.compactMap { $0.totalCarbs }.reduce(0, +)
    }
    
    var totalCaloriesFromAI: Double {
        return aiAnalyzedMeals().compactMap { $0.calories }.reduce(0, +)
    }
    
    var aiAnalysisPercentage: Double {
        guard !meals.isEmpty else { return 0 }
        let aiCount = aiAnalyzedMeals().count
        return Double(aiCount) / Double(meals.count) * 100
    }
    
    // MARK: - Persistencia
    
    private func saveToUserDefaults() {
        do {
            let encoded = try JSONEncoder().encode(meals)
            UserDefaults.standard.set(encoded, forKey: "SavedMeals")
        } catch {
            print("Error saving meals: \(error.localizedDescription)")
        }
    }
    
    private func loadFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: "SavedMeals") else { return }
        
        do {
            self.meals = try JSONDecoder().decode([Meal].self, from: data)
        } catch {
            print("Error loading meals: \(error.localizedDescription)")
            // Si hay error, inicializar con array vacío
            self.meals = []
        }
    }
    
    // MARK: - Métodos de utilidad
    
    func clearAllMeals() {
        meals.removeAll()
        saveToUserDefaults()
    }
    
    func exportMealsAsJSON() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(meals)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error exporting meals: \(error.localizedDescription)")
            return nil
        }
    }
}