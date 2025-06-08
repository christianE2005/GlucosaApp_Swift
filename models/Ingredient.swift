import Foundation
import SwiftUI



enum GlycemicIndex: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { self.rawValue }
}

/// Make sure IngredientCategory conforms to Decodable
// Example:
enum IngredientCategory: String, Codable, CaseIterable, Identifiable {
    case vegetable
    case fruit
    case grain
    case protein
    case dairy
    case fat

    var id: String { self.rawValue }
}
struct Ingredient: Identifiable, Decodable {
    let id: UUID
    let name: String
    let category: IngredientCategory
    let glycemicIndex: GlycemicIndex
    let carbsPer100g: Double
    let proteinsPer100g: Double
    let fatsPer100g: Double
    let caloriesPer100g: Double

    init(id: UUID = UUID(), name: String, category: IngredientCategory, glycemicIndex: GlycemicIndex, carbsPer100g: Double, proteinsPer100g: Double, fatsPer100g: Double, caloriesPer100g: Double) {
        self.id = id
        self.name = name
        self.category = category
        self.glycemicIndex = glycemicIndex
        self.carbsPer100g = carbsPer100g
        self.proteinsPer100g = proteinsPer100g
        self.fatsPer100g = fatsPer100g
        self.caloriesPer100g = caloriesPer100g
    }
}
