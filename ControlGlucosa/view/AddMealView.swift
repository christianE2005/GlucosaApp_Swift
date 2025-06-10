import SwiftUI
import Foundation

struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var meals: Meals
    
    @State private var name = ""
    @State private var selectedType: MealType = .breakfast
    @State private var glucoseLevel = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información de la comida")) {
                    TextField("Nombre de la comida", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Tipo", selection: $selectedType) {
                        ForEach(MealType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Nivel de glucosa (mg/dL)", text: $glucoseLevel)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    DatePicker("Fecha y hora", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                }
                
                Section(header: Text("Información adicional")) {
                    Text("El nivel de glucosa te ayudará a hacer seguimiento de cómo diferentes comidas afectan tu glucemia.")
                        .font(.caption)
                        .foregroundColor(Color.gray)
                }
            }
            .navigationTitle("Nueva Comida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let glucose = Double(glucoseLevel) ?? 0.0
                        let newMeal = Meal(
                            name: name,
                            type: selectedType,
                            portions: [],
                            timestamp: date,
                            glucoseReadingBefore: nil,
                            glucoseReadingAfter: nil,
                            totalCarbs: nil,
                            glucoseLevel: glucose,
                            date: date
                        )
                        meals.addMeal(newMeal)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(name.isEmpty ? Color.gray : Color.blue)
                }
            }
        }
    }
}
