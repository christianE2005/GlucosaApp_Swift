//
//  ContentView.swift
//  ControlGlucosa
//
//  Created by Alumno on 07/06/25.
//

import SwiftUI

struct ContentView: View {
    @state private var meals: [Meal] = []
    @state private var showingAddMeal = false
    
    var body: some View {
        NavigationView {
            VStack {
                List(meals) { meal in
                    MealRow(meal: meal)
                }
            }
        }
    }
}

