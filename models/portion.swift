//
//  portion.swift
//  ControlGlucosa
//
//  Created by Alumno on 07/06/25.
//

import Foundation

// MARK: - Ingredient Structure
struct Ingredient: Identifiable, Codable {
    var id = UUID() // Esto satisface el protocolo Identifiable
    let name: String
    let carbohydrates: Double
    let calories: Double
    let category: IngredientCategory
    let glycemicIndex: GlycemicIndex
    
    // Inicializador personalizado
    init(name: String, carbohydrates: Double, calories: Double, category: IngredientCategory = .other, glycemicIndex: GlycemicIndex = .medium) {
        self.name = name
        self.carbohydrates = carbohydrates
        self.calories = calories
        self.category = category
        self.glycemicIndex = glycemicIndex
    }
}

// MARK: - Portion Structure
struct Portion: Identifiable, Codable {
    var id = UUID() // Propiedad requerida por Identifiable
    let ingredient: Ingredient
    let amount: Double
    let unit: String
    
    // Propiedades calculadas para facilitar el uso
    var totalCarbohydrates: Double {
        return (ingredient.carbohydrates * amount) / 100.0 // Asumiendo que los valores son por 100g
    }
    
    var totalCalories: Double {
        return (ingredient.calories * amount) / 100.0
    }
    
    // Inicializador personalizado
    init(ingredient: Ingredient, amount: Double, unit: String) {
        self.ingredient = ingredient
        self.amount = amount
        self.unit = unit
    }
}

// MARK: - Extensions for Portion
extension Portion: CustomStringConvertible {
    var description: String {
        return "\(amount) \(unit) de \(ingredient.name) - \(String(format: "%.1f", totalCarbohydrates))g carbohidratos"
    }
}

// MARK: - Sample Data
extension Ingredient {
    static let sampleIngredients: [Ingredient] = [
        Ingredient(name: "Arroz blanco", carbohydrates: 78.0, calories: 365.0, category: .grain, glycemicIndex: .high),
        Ingredient(name: "Pollo a la plancha", carbohydrates: 0.0, calories: 165.0, category: .protein, glycemicIndex: .low),
        Ingredient(name: "Brócoli", carbohydrates: 7.0, calories: 34.0, category: .vegetable, glycemicIndex: .low),
        Ingredient(name: "Manzana", carbohydrates: 14.0, calories: 52.0, category: .fruit, glycemicIndex: .medium)
    ]
}
