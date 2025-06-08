//
//  portion.swift
//  ControlGlucosa
//
//  Created by Alumno on 07/06/25.
//

import Foundation

struct Portion: Identifiable, Codable {
    let id = UUID()
    let ingredient: Ingredient
    let amount: Double
    let unit: String
}