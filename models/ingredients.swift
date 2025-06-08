import Foundation

enum IngredientCategory {
    case grains
    case proteins
    case vegetables
}

enum GlycemicIndex {
    case low
    case medium
    case high
}

struct Ingredient {
    let name: String
    let category: IngredientCategory
    let glycemicIndex: GlycemicIndex
    let carbsPer100g: Double
    let proteinsPer100g: Double
    let fatsPer100g: Double
    let caloriesPer100g: Int
}

// Sample ingredients data
extension Ingredient {
    static let sampleIngredients: [Ingredient] = [
        Ingredient(
            name: "Arroz blanco",
            category: .grains,
            glycemicIndex: .high,
            carbsPer100g: 28.0,
            proteinsPer100g: 2.7,
            fatsPer100g: 0.2,
            caloriesPer100g: 130
        ),
        Ingredient(
            name: "Pollo",
            category: .proteins,
            glycemicIndex: .low,
            carbsPer100g: 0.0,
            proteinsPer100g: 31.0,
            fatsPer100g: 3.6,
            caloriesPer100g: 165
        ),
        Ingredient(
            name: "Brócoli",
            category: .vegetables,
            glycemicIndex: .low,
            carbsPer100g: 7.0,
            proteinsPer100g: 2.8,
            fatsPer100g: 0.4,
            caloriesPer100g: 34
        )
    ]
}
