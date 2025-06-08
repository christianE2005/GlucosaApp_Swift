import SwiftUI

struct Meal {
    let name: String
    let type: MealType
    let totalCarbs: Double
}

enum MealType: String {
    case breakfast = "Desayuno"
    case lunch = "Almuerzo"
    case dinner = "Cena"
    case snack = "Snack"
}

struct MealRow: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(meal.name)
                .font(.headline)
            Text(meal.type.rawValue)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Carbohidratos: \(meal.totalCarbs, specifier: "%.1f")g")
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
}
