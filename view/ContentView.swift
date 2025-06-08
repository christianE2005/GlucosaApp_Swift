//
//  ContentView.swift
//  ControlGlucosa
//
//  Created by Alumno on 07/06/25.
//

import SwiftUI

struct Meal: Identifiable {
    let id = UUID()
    let name: String
    let glucoseLevel: Double
    let date: Date
}

// A view to add a new meal
struct AddMealView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var meals: [Meal]
    @State private var name: String = ""
    @State private var glucoseLevel: String = ""
    @State private var date: Date = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nombre de la comida")) {
                    TextField("Ejemplo: Desayuno", text: $name)
                }
                Section(header: Text("Nivel de glucosa (mg/dL)")) {
                    TextField("Ejemplo: 110", text: $glucoseLevel)
                }
                Section(header: Text("Fecha")) {
                    DatePicker("Selecciona la fecha", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Agregar comida")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if let glucose = Double(glucoseLevel), !name.isEmpty {
                            let newMeal = Meal(name: name, glucoseLevel: glucose, date: date)
                            meals.append(newMeal)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }
}

// A view to display a single meal row
struct MealRow: View {
    let meal: Meal

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(meal.name)
                    .font(.headline)
                Text("Glucosa: \(meal.glucoseLevel, specifier: "%.1f") mg/dL")
                    .font(.subheadline)
                Text(meal.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ContentView: View {
    @State private var meals: [Meal] = []
    @State private var showingAddMeal = false
    
    var body: some View {
        NavigationView {
            VStack {
                List(meals) { meal in
                    MealRow(meal: meal)
                }
                
                Button("Agregar comida") {
                    showingAddMeal = true
                }
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
                .accessibilityLabel("Agregar comida")
            }
            .navigationTitle("Registro de Comias")
            .sheet(isPresented: $showingAddMeal){
                AddMealView(meals: $meals)
            }
        }
    }
}

