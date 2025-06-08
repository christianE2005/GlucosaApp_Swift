//
//  ModelsImport.swift
//  ControlGlucosa
//
//  Archivo para asegurar que todos los modelos estén disponibles
//

import Foundation
import SwiftUI
import Combine

// Re-exportar todos los tipos principales para asegurar disponibilidad
/*
public typealias AppMeal = Meal
public typealias AppMealType = MealType
public typealias AppIngredient = Ingredient
public typealias AppPortion = Portion
public typealias AppGlucoseReading = GlucoseReading
*/
// Extensión para verificar que los tipos estén disponibles
extension Meal {
    static func verify() -> Bool {
        return true
    }
}

extension MealType {
    static func verify() -> Bool {
        return true
    }
}

// Función global para debugging si es necesario
func debugModelAvailability() {
    print("✅ Meal type available: \(Meal.verify())")
    print("✅ MealType enum available: \(MealType.verify())")
}
