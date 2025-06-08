import SwiftUI

enum MealType: String, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: String { self.rawValue }
}

struct Meal: Identifiable {
    let id = UUID()
    var name: String
    var type: MealType
    var portions: [String]
    var timestamp: Date
    var glucoseReadingBefore: Double?
    var glucoseReadingAfter: Double?
}

struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var meals: [Meal]
    @State private var name = ""
    @State private var selectedType: MealType = .breakfast
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Nombre de la comida", text: $name)
                Picker("Tipo", selection: $selectedType) {
                    Text("Desayuno").tag(MealType.breakfast)
                    Text("Almuerzo").tag(MealType.lunch)
                    Text("Cena").tag(MealType.dinner)
                    Text("Merienda").tag(MealType.snack)
                }
            }
            .navigationTitle("Nueva Comida")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let newMeal = Meal(name: name,
                                         type: selectedType,
                                         portions: [],
                                         timestamp: Date(),
                                         glucoseReadingBefore: nil,
                                         glucoseReadingAfter: nil)
                        meals.append(newMeal)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
