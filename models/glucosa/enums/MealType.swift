import Foundation

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack
    
    var id: String { rawValue }
    
    var rawValue: String {
        switch self {
        case .breakfast: return "Desayuno"
        case .lunch: return "Almuerzo"
        case .dinner: return "Cena"
        case .snack: return "Merienda"
        }
    }
}
