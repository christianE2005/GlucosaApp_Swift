import SwiftUI
import Foundation

struct MealRow: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Nombre y tipo de comida
            HStack {
                Text(meal.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(meal.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            // Información nutricional
            VStack(alignment: .leading, spacing: 3) {
                if let totalCarbs = meal.totalCarbs {
                    Text("Carbohidratos: \(String(format: "%.1f", totalCarbs))g")
                        .font(.caption)
                        .foregroundColor(Color.gray)
                }
                
                if let glucoseLevel = meal.glucoseLevel {
                    HStack {
                        Text("Glucosa: \(String(format: "%.1f", glucoseLevel)) mg/dL")
                            .font(.caption)
                            .foregroundColor(Color.gray)
                        
                        // Indicador visual del nivel de glucosa
                        Circle()
                            .fill(glucoseColor(for: glucoseLevel))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            // Fecha y hora
            Text(meal.date, style: .date)
                .font(.caption2)
                .foregroundColor(Color.gray.opacity(0.7))
        }
        .padding(.vertical, 8)
    }
    
    // Función auxiliar para determinar el color según el nivel de glucosa
    private func glucoseColor(for level: Double) -> Color {
        switch level {
        case 0...70:
            return Color.red // Bajo
        case 71...99:
            return Color.green // Normal
        case 100...125:
            return Color.orange // Prediabetes
        default:
            return Color.red // Alto
        }
    }
}
