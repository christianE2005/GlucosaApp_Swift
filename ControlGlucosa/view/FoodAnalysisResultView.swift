import SwiftUI

struct FoodAnalysisResultView: View {
    let result: FoodAnalysisResult
    let originalImage: UIImage
    let onDismiss: () -> Void
    
    @EnvironmentObject var meals: Meals
    @State private var showingSaveConfirmation = false
    @State private var customPortionSize: String = ""
    @State private var notes: String = ""
    @State private var selectedMealType: MealType = .breakfast
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header con resultado de IA
                    AIResultHeader(result: result, originalImage: originalImage)
                    
                    // Información nutricional detallada
                    NutritionalAnalysisCard(nutritionalInfo: result.nutritionalInfo)
                    
                    // Insights específicos para diabetes
                    if !result.healthInsights.isEmpty {
                        DiabetesInsightsCard(insights: result.healthInsights)
                    }
                    
                    // Impacto glucémico con visualización
                    GlucoseImpactVisualizationCard(nutritionalInfo: result.nutritionalInfo)
                    
                    // Sección para guardar en el historial
                    SaveToHistoryCard(
                        foodName: result.foodName,
                        selectedMealType: $selectedMealType,
                        portionSize: $customPortionSize,
                        notes: $notes,
                        onSave: saveMealToHistory
                    )
                }
                .padding()
            }
            .navigationTitle("Análisis IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        onDismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Compartir") {
                        shareResults()
                    }
                    .foregroundColor(.blue)
                }
            }
            .alert("¡Guardado Exitosamente!", isPresented: $showingSaveConfirmation) {
                Button("Ver Gráficas IA") {
                    onDismiss()
                    // Notificar que se debe navegar a la tab de Insights
                    NotificationCenter.default.post(name: .navigateToInsights, object: nil)
                }
                Button("Analizar Otra") {
                    onDismiss()
                }
            } message: {
                Text("🧠 ¡Análisis IA agregado! Los datos nutricionales ya están disponibles en tus gráficas e insights.")
            }
        }
    }
    
    private func saveMealToHistory() {
        let portionSize = Double(customPortionSize) ?? result.nutritionalInfo.portionSize
        let adjustedNutrition = adjustNutritionForPortion(
            original: result.nutritionalInfo,
            newPortion: portionSize
        )
        
        let meal = Meal(
            name: "🧠 \(result.foodName)",
            type: selectedMealType,
            portions: ["Análisis IA: \(Int(portionSize))g"],
            timestamp: Date(),
            glucoseReadingBefore: nil,
            glucoseReadingAfter: nil,
            totalCarbs: adjustedNutrition.carbohydrates,
            glucoseLevel: nil,
            date: Date(),
            // ✨ NUEVOS: Datos nutricionales completos
            calories: adjustedNutrition.calories,
            proteins: adjustedNutrition.proteins,
            fats: adjustedNutrition.fats,
            fiber: adjustedNutrition.fiber,
            sugars: adjustedNutrition.sugars,
            sodium: adjustedNutrition.sodium,
            glycemicIndex: adjustedNutrition.glycemicIndex,
            portionSizeGrams: portionSize,
            isAIAnalyzed: true
        )
        
        meals.addMeal(meal)
        
        // 🚨 Notificar que se agregaron nuevos datos de IA
        NotificationCenter.default.post(name: .newAIDataAdded, object: nil)
        
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
    
    private func shareResults() {
        let shareText = """
        🧠 Análisis Nutricional con IA: \(result.foodName)
        
        📊 Información por \(Int(result.nutritionalInfo.portionSize))g:
        • Calorías: \(Int(result.nutritionalInfo.calories))
        • Carbohidratos: \(Int(result.nutritionalInfo.carbohydrates))g
        • Proteínas: \(Int(result.nutritionalInfo.proteins))g
        • Grasas: \(Int(result.nutritionalInfo.fats))g
        • Fibra: \(Int(result.nutritionalInfo.fiber))g
        
        🩸 Índice Glucémico: \(result.nutritionalInfo.glycemicIndex.rawValue.capitalized)
        📈 Carga Glucémica: \(String(format: "%.1f", result.nutritionalInfo.glycemicLoad))
        🎯 Impacto: \(result.nutritionalInfo.carbsPerGlucoseImpact)
        
        🤖 Confianza IA: \(Int(result.confidence * 100))%
        
        Generado por Gluco Log con MobileNetV2
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

// MARK: - Header con resultado de IA

struct AIResultHeader: View {
    let result: FoodAnalysisResult
    let originalImage: UIImage
    
    var body: some View {
        VStack(spacing: 20) {
            // Imagen analizada
            Image(uiImage: originalImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .overlay(
                    // Badge de IA
                    VStack {
                        HStack {
                            Spacer()
                            AIBadge()
                        }
                        Spacer()
                    }
                    .padding(12)
                )
            
            // Resultado de la clasificación
            VStack(spacing: 12) {
                Text(result.foodName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // Confianza de la IA con indicador visual
                HStack(spacing: 12) {
                    Image(systemName: "brain")
                        .foregroundColor(confidenceColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Confianza de la IA: \(Int(result.confidence * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(confidenceColor)
                        
                        Text(confidenceDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Barra de confianza
                    ProgressView(value: result.confidence, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor))
                        .frame(width: 60)
                }
                .padding()
                .background(confidenceColor.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var confidenceColor: Color {
        switch result.confidence {
        case 0.85...1.0:
            return .green
        case 0.7..<0.85:
            return .orange
        default:
            return .red
        }
    }
    
    private var confidenceDescription: String {
        switch result.confidence {
        case 0.85...1.0:
            return "Muy alta precisión"
        case 0.7..<0.85:
            return "Buena precisión"
        default:
            return "Verificar manualmente"
        }
    }
}

struct AIBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "brain.head.profile")
                .font(.caption2)
            Text("IA")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue)
        .cornerRadius(8)
    }
}

// MARK: - Card de análisis nutricional

struct NutritionalAnalysisCard: View {
    let nutritionalInfo: NutritionalInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Análisis Nutricional Detallado")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("por \(Int(nutritionalInfo.portionSize))g")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                NutrientCard(
                    name: "Calorías", 
                    value: Int(nutritionalInfo.calories), 
                    unit: "kcal", 
                    color: .red,
                    percentage: caloriePercentage
                )
                NutrientCard(
                    name: "Carbohidratos", 
                    value: Int(nutritionalInfo.carbohydrates), 
                    unit: "g", 
                    color: .orange,
                    percentage: carbPercentage
                )
                NutrientCard(
                    name: "Proteínas", 
                    value: Int(nutritionalInfo.proteins), 
                    unit: "g", 
                    color: .green,
                    percentage: proteinPercentage
                )
                NutrientCard(
                    name: "Grasas", 
                    value: Int(nutritionalInfo.fats), 
                    unit: "g", 
                    color: .purple,
                    percentage: fatPercentage
                )
                NutrientCard(
                    name: "Fibra", 
                    value: Int(nutritionalInfo.fiber), 
                    unit: "g", 
                    color: .brown,
                    percentage: fiberPercentage
                )
                NutrientCard(
                    name: "Azúcares", 
                    value: Int(nutritionalInfo.sugars), 
                    unit: "g", 
                    color: .pink,
                    percentage: sugarPercentage
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Porcentajes aproximados basados en recomendaciones diarias (2000 kcal)
    private var caloriePercentage: Double { min(nutritionalInfo.calories / 2000 * 100, 100) }
    private var carbPercentage: Double { min(nutritionalInfo.carbohydrates / 300 * 100, 100) }
    private var proteinPercentage: Double { min(nutritionalInfo.proteins / 150 * 100, 100) }
    private var fatPercentage: Double { min(nutritionalInfo.fats / 65 * 100, 100) }
    private var fiberPercentage: Double { min(nutritionalInfo.fiber / 25 * 100, 100) }
    private var sugarPercentage: Double { min(nutritionalInfo.sugars / 50 * 100, 100) }
}

struct NutrientCard: View {
    let name: String
    let value: Int
    let unit: String
    let color: Color
    let percentage: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // Barra de progreso
            ProgressView(value: percentage, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text("\(Int(percentage))% VD*")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Card de insights para diabetes

struct DiabetesInsightsCard: View {
    let insights: [HealthInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("Insights IA para Diabetes")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            ForEach(insights.indices, id: \.self) { index in
                InsightCard(insight: insights[index])
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct InsightCard: View {
    let insight: HealthInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icono con color de severidad
            ZStack {
                Circle()
                    .fill(severityColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: insight.category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(severityColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var severityColor: Color {
        switch insight.severity {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
}

// MARK: - Card de impacto glucémico con visualización

struct GlucoseImpactVisualizationCard: View {
    let nutritionalInfo: NutritionalInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.red)
                Text("Impacto en Glucosa")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 16) {
                // Visualización del índice glucémico
                VStack(alignment: .leading, spacing: 8) {
                    Text("Índice Glucémico")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Bajo")
                            .font(.caption)
                        Spacer()
                        Text("Medio")
                            .font(.caption)
                        Spacer()
                        Text("Alto")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    // Barra de IG
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.green, .orange, .red]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        // Indicador de posición
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                            .shadow(radius: 2)
                            .offset(x: glycemicIndexPosition)
                    }
                    
                    Text("\(nutritionalInfo.glycemicIndex.rawValue.capitalized)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(glycemicIndexColor)
                }
                
                // Métricas de impacto
                HStack(spacing: 20) {
                    ImpactMetric(
                        title: "Carga Glucémica",
                        value: String(format: "%.1f", nutritionalInfo.glycemicLoad),
                        color: glycemicLoadColor
                    )
                    
                    ImpactMetric(
                        title: "Impacto Esperado",
                        value: nutritionalInfo.carbsPerGlucoseImpact,
                        color: impactColor
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var glycemicIndexPosition: CGFloat {
        switch nutritionalInfo.glycemicIndex {
        case .low: return 25
        case .medium: return 125
        case .high: return 225
        }
    }
    
    private var glycemicIndexColor: Color {
        switch nutritionalInfo.glycemicIndex {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private var glycemicLoadColor: Color {
        let load = nutritionalInfo.glycemicLoad
        switch load {
        case 0...10: return .green
        case 11...19: return .orange
        default: return .red
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

struct ImpactMetric: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Card para guardar en historial

struct SaveToHistoryCard: View {
    let foodName: String
    @Binding var selectedMealType: MealType
    @Binding var portionSize: String
    @Binding var notes: String
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "square.and.arrow.down.fill")
                    .foregroundColor(.green)
                Text("Guardar en Historial")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 16) {
                // Tipo de comida
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tipo de Comida")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Tipo", selection: $selectedMealType) {
                        ForEach(MealType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Porción
                VStack(alignment: .leading, spacing: 8) {
                    Text("Porción (gramos)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        TextField("100", text: $portionSize)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("gramos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Notas opcionales
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notas (opcional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Ej: Almuerzo en casa, muy sabroso", text: $notes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // Botón de guardar
            Button(action: onSave) {
                HStack(spacing: 12) {
                    Image(systemName: "brain")
                    Text("Guardar Análisis IA")
                        .fontWeight(.semibold)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}