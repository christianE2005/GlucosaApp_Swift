//
//  meal.swift
//  ControlGlucosa
//
//  Created by Alumno on 07/06/25.
//

import Foundation

struct Meal: Identifiable {
    let id = UUID()
    let name : String
    let ingredients : [String]
    let time : Date
    let type : String
    
}

