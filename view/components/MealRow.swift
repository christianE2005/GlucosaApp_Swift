import SwiftUI

struct MealRow: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(meal.name)
                .font(.headline)
            Text(meal.type.rawValue)
                .font(.subheadline)
                .foregroundColor(.secondary)
            if let totalCarbs = meal.totalCarbs {
                Text("Carbohidratos: \(totalCarbs, specifier: "%.1f")g")
                    .font(.caption)
            }
            if let glucoseLevel = meal.glucoseLevel {
                Text("Glucosa: \(glucoseLevel, specifier: "%.1f") mg/dL")
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
    }
}
