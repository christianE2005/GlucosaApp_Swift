//
//  portion.swift
//  ControlGlucosa
//
//  Created by Alumno on 07/06/25.
//

import Foundation
// Add this above Portion if Ingredient doesn't exist
struct Ingredient: Identifiable, Codable {
    let name: String
    let carbohydrates: Double
    let calories: Double
}

extension Portion: Identifiable, Encodable {
    let ingredient: Ingredient
    let amount: Double
    let unit: String
    
    // Custom initializer
    init(ingredient: Ingredient, amount: Double, unit: String) {
        self.id = UUID()
        self.ingredient = ingredient
        self.amount = amount
        self.unit = unit
    }
}
