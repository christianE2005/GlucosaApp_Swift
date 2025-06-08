import SwiftUI

struct FoodAnalysisResultView: View {
    let result: FoodAnalysisResult
    let originalImage: UIImage
    let onDismiss: () -> Void
    
    @EnvironmentObject var meals: Meals
    @State private var showingSaveConfirmation = false
    @State private var customPortionSize: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header con imagen y resultado
                    VStack(spacing: 16) {
                        Image(uiImage: originalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 8) {
                            Text(result.foodName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(confidenceColor)
                                
                                Text("Confianza: \(Int(result.confidence * 100))%")
                                    .font(.subheadline)
                                    .foregroundColor(confidenceColor)
                            }
                        }
                    }
                    
                    // Información nutricional
                    NutritionalInfoCard(nutritionalInfo: result.nutritionalInfo)
                    
                    // Insights de salud
                    if !result.healthInsights.isEmpty {
                        HealthInsightsCard(insights: result.healthInsights)
                    }
                    
                    // Impacto en glucosa
                    GlucoseImpactCard(nutritionalInfo: result.nutritionalInfo)
                    
                    // Sección para guardar
                    SaveMealCard(
                        foodName: result.foodName,
                        portionSize: $customPortionSize,
                        notes: $notes,
                        onSave: saveMeal
                    )
                }
                .padding()
            }
            .navigationTitle("Análisis Completo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Compartir") {
                        shareResults()
                    }
                }
            }
            .alert("Comida Guardada", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    onDismiss()
                }
            } message: {
                Text("La información nutricional ha sido agregada a tu registro de comidas.")
            }
        }
    }
    
    private var confidenceColor: Color {
        switch result.confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private func saveMeal() {
        let portionSize = Double(customPortionSize) ?? result.nutritionalInfo.portionSize
        let adjustedNutrition = adjustNutritionForPortion(
            original: result.nutritionalInfo,
            newPortion: portionSize
        )
        
        let meal = Meal(
            name: result.foodName,
            type: getCurrentMealType(),
            portions: ["Análisis automático: \(Int(portionSize))g"],
            timestamp: Date(),
            glucoseReadingBefore: nil,
            glucoseReadingAfter: nil,
            totalCarbs: adjustedNutrition.carbohydrates,
            glucoseLevel: nil,
            date: Date()
        )
        
        meals.addMeal(meal)
        showingSaveConfirmation = true
    }
    
    private func adjustNutritionForPortion(original: NutritionalInfo, newPortion: Double) -> NutritionalInfo {
        let factor = newPortion / original.portionSize
        
        return NutritionalInfo(
            calories: original.calories * factor,
            carbohydrates: original.carbohydrates * factor,
            proteins: original.proteins * factor,
            fats: original.fats * factor,
            fiber: original.fiber * factor,
            sugars: original.sugars * factor,
            sodium: original.sodium * factor,
            glycemicIndex: original.glycemicIndex,
            portionSize: newPortion
        )
    }
    
    private func getCurrentMealType() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5...11:
            return .breakfast
        case 12...16:
            return .lunch
        case 17...22:
            return .dinner
        default:
            return .snack
        }
    }
    
    private func shareResults() {
        // Implementar compartir resultados
        let shareText = """
        🍎 Análisis Nutricional: \(result.foodName)
        
        📊 Información por \(Int(result.nutritionalInfo.portionSize))g:
        • Calorías: \(Int(result.nutritionalInfo.calories))
        • Carbohidratos: \(Int(result.nutritionalInfo.carbohydrates))g
        • Proteínas: \(Int(result.nutritionalInfo.proteins))g
        • Grasas: \(Int(result.nutritionalInfo.fats))g
        
        🩸 Impacto en Glucosa: \(result.nutritionalInfo.carbsPerGlucoseImpact)
        
        Generado por Control de Glucosa App
        """
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareText, originalImage],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
}

// MARK: - Cards de información

struct NutritionalInfoCard: View {
    let nutritionalInfo: NutritionalInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Información Nutricional")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(nutritionalInfo.portionSize))g")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                NutrientItem(name: "Calorías", value: "\(Int(nutritionalInfo.calories))", unit: "kcal", color: .red)
                NutrientItem(name: "Carbohidratos", value: "\(Int(nutritionalInfo.carbohydrates))", unit: "g", color: .orange)
                NutrientItem(name: "Proteínas", value: "\(Int(nutritionalInfo.proteins))", unit: "g", color: .green)
                NutrientItem(name: "Grasas", value: "\(Int(nutritionalInfo.fats))", unit: "g", color: .purple)
                NutrientItem(name: "Fibra", value: "\(Int(nutritionalInfo.fiber))", unit: "g", color: .brown)
                NutrientItem(name: "Azúcares", value: "\(Int(nutritionalInfo.sugars))", unit: "g", color: .pink)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct NutrientItem: View {
    let name: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

struct HealthInsightsCard: View {
    let insights: [HealthInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Insights de Salud")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            ForEach(insights.indices, id: \.self) { index in
                InsightRow(insight: insights[index])
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct InsightRow: View {
    let insight: HealthInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.category.icon)
                .foregroundColor(Color(insight.severity.color))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct GlucoseImpactCard: View {
    let nutritionalInfo: NutritionalInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.red)
                Text("Impacto en Glucosa")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Índice Glucémico:")
                    Spacer()
                    Text(nutritionalInfo.glycemicIndex.rawValue.capitalized)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(glycemicIndexColor.opacity(0.2))
                        .foregroundColor(glycemicIndexColor)
                        .cornerRadius(8)
                }
                
                HStack {
                    Text("Carga Glucémica:")
                    Spacer()
                    Text("\(String(format: "%.1f", nutritionalInfo.glycemicLoad))")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Impacto Esperado:")
                    Spacer()
                    Text(nutritionalInfo.carbsPerGlucoseImpact)
                        .fontWeight(.semibold)
                        .foregroundColor(impactColor)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var glycemicIndexColor: Color {
        switch nutritionalInfo.glycemicIndex {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private var impactColor: Color {
        switch nutritionalInfo.carbsPerGlucoseImpact {
        case "Bajo impacto": return .green
        case "Impacto moderado": return .orange
        default: return .red
        }
    }
}

struct SaveMealCard: View {
    let foodName: String
    @Binding var portionSize: String
    @Binding var notes: String
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "square.and.arrow.down.fill")
                    .foregroundColor(.green)
                Text("Guardar en Mis Comidas")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Porción (gramos):")
                    Spacer()
                    TextField("100", text: $portionSize)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notas (opcional):")
                    TextField("Ej: Almuerzo en casa", text: $notes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            Button(action: onSave) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Agregar a Mis Comidas")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}