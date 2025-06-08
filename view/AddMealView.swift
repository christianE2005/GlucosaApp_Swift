import SwiftUI

struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var meals: [Meal]
    @State private var name = ""
    @State private var selectedType: MealType = .breakfast
    @State private var glucoseLevel = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Nombre de la comida", text: $name)
                Picker("Tipo", selection: $selectedType) {
                    ForEach(MealType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                TextField("Nivel de glucosa (mg/dL)", text: $glucoseLevel)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Nueva Comida")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let glucose = Double(glucoseLevel)
                        let newMeal = Meal(
                            name: name,
                            type: selectedType,
                            portions: [],
                            timestamp: Date(),
                            glucoseReadingBefore: nil,
                            glucoseReadingAfter: nil,
                            totalCarbs: nil,
                            glucoseLevel: glucose,
                            date: Date()
                        )
                        meals.append(newMeal)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
