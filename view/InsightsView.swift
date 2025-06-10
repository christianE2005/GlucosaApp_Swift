import SwiftUI

// MARK: - Main Insights View
struct InsightsView: View {
    @EnvironmentObject var meals: Meals
    @EnvironmentObject var userProfiles: UserProfiles
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedChartType: ChartType = .glucose
    @State private var showingDetailView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header con selector de tiempo
                    TimeRangeSelector(selectedTimeRange: $selectedTimeRange)
                    
                    // Métricas principales
                    MainMetricsCard(meals: filteredMeals)
                    
                    // Gráfica principal con selector de tipo
                    EnhancedTrendsAnalysisCard(
                        meals: filteredMeals,
                        timeRange: selectedTimeRange
                    )
                    
                    // Desglose nutricional
                    NutritionalBreakdownCard(meals: filteredMeals)
                    
                    // Insights de IA
                    if hasAIAnalyzedMeals {
                        AIInsightsCard(meals: aiAnalyzedMeals)
                    }
                    
                    // Patrones de glucosa
                    GlucosePatternsCard(meals: filteredMeals)
                    
                    // Recomendaciones
                    RecommendationsCard(meals: filteredMeals)
                }
                .padding()
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDetailView = true }) {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showingDetailView) {
                DetailedInsightsView(meals: filteredMeals)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredMeals: [Meal] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .day:
            return meals.meals.filter { calendar.isDate($0.date, inSameDayAs: now) }
        case .week:
            return meals.meals.filter { 
                calendar.dateInterval(of: .weekOfYear, for: now)?.contains($0.date) ?? false 
            }
        case .month:
            return meals.meals.filter { 
                calendar.dateInterval(of: .month, for: now)?.contains($0.date) ?? false 
            }
        case .year:
            return meals.meals.filter { 
                calendar.dateInterval(of: .year, for: now)?.contains($0.date) ?? false 
            }
        }
    }
    
    private var aiAnalyzedMeals: [Meal] {
        return filteredMeals.filter { $0.isAIAnalyzed }
    }
    
    private var hasAIAnalyzedMeals: Bool {
        return !aiAnalyzedMeals.isEmpty
    }
}

// MARK: - Time Range Selector
struct TimeRangeSelector: View {
    @Binding var selectedTimeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Período de Análisis")
                .font(.headline)
                .fontWeight(.semibold)
            
            Picker("Rango de Tiempo", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Main Metrics Card
struct MainMetricsCard: View {
    let meals: [Meal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Métricas Principales")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Comidas Registradas",
                    value: "\(meals.count)",
                    subtitle: "total",
                    color: .blue,
                    icon: "list.bullet"
                )
                
                MetricCard(
                    title: "Análisis con IA",
                    value: "\(aiAnalyzedMeals)",
                    subtitle: "comidas",
                    color: .purple,
                    icon: "brain"
                )
                
                MetricCard(
                    title: "Glucosa Promedio",
                    value: averageGlucose > 0 ? "\(Int(averageGlucose))" : "N/A",
                    subtitle: "mg/dL",
                    color: glucoseColor,
                    icon: "drop.fill"
                )
                
                MetricCard(
                    title: "Calorías IA",
                    value: "\(Int(totalCaloriesFromAI))",
                    subtitle: "kcal total",
                    color: .green,
                    icon: "flame.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var aiAnalyzedMeals: Int {
        return meals.filter { $0.isAIAnalyzed }.count
    }
    
    private var totalCaloriesFromAI: Double {
        return meals.compactMap { $0.calories }.reduce(0, +)
    }
    
    private var averageGlucose: Double {
        let glucoseValues = meals.compactMap { $0.glucoseLevel }
        return glucoseValues.isEmpty ? 0 : glucoseValues.reduce(0, +) / Double(glucoseValues.count)
    }
    
    private var glucoseColor: Color {
        switch averageGlucose {
        case 0...70: return .blue
        case 71...99: return .green
        case 100...140: return .orange
        default: return .red
        }
    }
}

// MARK: - Enhanced Trends Analysis Card
struct EnhancedTrendsAnalysisCard: View {
    let meals: [Meal]
    let timeRange: TimeRange
    @State private var selectedChartType: ChartType = .glucose
    @State private var showingChartDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.blue)
                Text("Análisis de Tendencias")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { showingChartDetails = true }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
            
            // Selector de tipo de gráfica
            ChartTypeSelector(selectedChartType: $selectedChartType)
            
            // Gráfica dinámica
            DynamicChartSection()
            
            // Estadísticas resumidas
            SummaryStatsSection()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingChartDetails) {
            ChartDetailsView(chartType: selectedChartType, meals: meals)
        }
    }
    
    @ViewBuilder
    private func ChartTypeSelector(selectedChartType: Binding<ChartType>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChartType.allCases, id: \.self) { chartType in
                    ChartTypeButton(
                        chartType: chartType,
                        isSelected: selectedChartType.wrappedValue == chartType
                    ) {
                        selectedChartType.wrappedValue = chartType
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func DynamicChartSection() -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: selectedChartType.icon)
                    .foregroundColor(selectedChartType.color)
                Text("Tendencia de \(selectedChartType.rawValue)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(timeRange.rawValue)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedChartType.color.opacity(0.1))
                    .foregroundColor(selectedChartType.color)
                    .cornerRadius(8)
            }
            
            Group {
                switch selectedChartType {
                case .glucose:
                    CustomGlucoseTrendChart(meals: meals)
                case .carbs:
                    CustomCarbsTrendChart(meals: meals)
                case .calories:
                    CustomCaloriesTrendChart(meals: meals)
                case .proteins:
                    CustomProteinsTrendChart(meals: meals)
                case .fats:
                    CustomFatsTrendChart(meals: meals)
                case .fiber:
                    CustomFiberTrendChart(meals: meals)
                case .glycemic:
                    CustomGlycemicImpactChart(meals: meals)
                case .categories:
                    CustomFoodCategoriesChart(meals: meals)
                }
            }
            .frame(height: 250)
            .animation(.easeInOut(duration: 0.5), value: selectedChartType)
        }
    }
    
    @ViewBuilder
    private func SummaryStatsSection() -> some View {
        HStack {
            StatItem(title: summaryStats.title1, value: summaryStats.value1)
            Spacer()
            StatItem(title: summaryStats.title2, value: summaryStats.value2)
            Spacer()
            StatItem(title: summaryStats.title3, value: summaryStats.value3)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var summaryStats: (title1: String, value1: String, title2: String, value2: String, title3: String, value3: String) {
        let aiMeals = meals.filter { $0.isAIAnalyzed }
        
        switch selectedChartType {
        case .glucose:
            let glucoseValues = meals.compactMap { $0.glucoseLevel }
            let avg = glucoseValues.isEmpty ? 0 : glucoseValues.reduce(0, +) / Double(glucoseValues.count)
            let max = glucoseValues.max() ?? 0
            let min = glucoseValues.min() ?? 0
            return ("Promedio", "\(Int(avg)) mg/dL", "Máximo", "\(Int(max)) mg/dL", "Mínimo", "\(Int(min)) mg/dL")
            
        case .carbs:
            let carbValues = meals.compactMap { $0.totalCarbs }
            let total = carbValues.reduce(0, +)
            let avg = carbValues.isEmpty ? 0 : total / Double(carbValues.count)
            let max = carbValues.max() ?? 0
            return ("Total", "\(Int(total))g", "Promedio", "\(Int(avg))g", "Máximo", "\(Int(max))g")
            
        case .calories:
            let calorieValues = aiMeals.compactMap { $0.calories }
            let total = calorieValues.reduce(0, +)
            let avg = calorieValues.isEmpty ? 0 : total / Double(calorieValues.count)
            let max = calorieValues.max() ?? 0
            return ("Total", "\(Int(total)) kcal", "Promedio", "\(Int(avg)) kcal", "Máximo", "\(Int(max)) kcal")
            
        case .proteins:
            let proteinValues = aiMeals.compactMap { $0.proteins }
            let total = proteinValues.reduce(0, +)
            let avg = proteinValues.isEmpty ? 0 : total / Double(proteinValues.count)
            let max = proteinValues.max() ?? 0
            return ("Total", "\(Int(total))g", "Promedio", "\(Int(avg))g", "Máximo", "\(Int(max))g")
            
        case .fats:
            let fatValues = aiMeals.compactMap { $0.fats }
            let total = fatValues.reduce(0, +)
            let avg = fatValues.isEmpty ? 0 : total / Double(fatValues.count)
            let max = fatValues.max() ?? 0
            return ("Total", "\(Int(total))g", "Promedio", "\(Int(avg))g", "Máximo", "\(Int(max))g")
            
        case .fiber:
            let fiberValues = aiMeals.compactMap { $0.fiber }
            let total = fiberValues.reduce(0, +)
            let avg = fiberValues.isEmpty ? 0 : total / Double(fiberValues.count)
            let max = fiberValues.max() ?? 0
            return ("Total", "\(Int(total))g", "Promedio", "\(Int(avg))g", "Máximo", "\(Int(max))g")
            
        case .glycemic:
            let lowGI = aiMeals.filter { $0.glycemicIndex == .low }.count
            let mediumGI = aiMeals.filter { $0.glycemicIndex == .medium }.count
            let highGI = aiMeals.filter { $0.glycemicIndex == .high }.count
            return ("IG Bajo", "\(lowGI)", "IG Medio", "\(mediumGI)", "IG Alto", "\(highGI)")
            
        case .categories:
            let breakfast = meals.filter { $0.type == .breakfast }.count
            let lunch = meals.filter { $0.type == .lunch }.count
            let dinner = meals.filter { $0.type == .dinner }.count
            return ("Desayuno", "\(breakfast)", "Almuerzo", "\(lunch)", "Cena", "\(dinner)")
        }
    }
}

// MARK: - Nutritional Breakdown Card
struct NutritionalBreakdownCard: View {
    let meals: [Meal]
    
    private var nutritionalSummary: (carbs: Double, avgCarbs: Double, aiMeals: Int, proteins: Double, fats: Double, fiber: Double) {
        let aiMeals = meals.filter { $0.isAIAnalyzed }
        let carbReadings = meals.compactMap { $0.totalCarbs }
        let totalCarbs = carbReadings.reduce(0, +)
        let avgCarbs = carbReadings.isEmpty ? 0 : totalCarbs / Double(carbReadings.count)
        
        let totalProteins = aiMeals.compactMap { $0.proteins }.reduce(0, +)
        let totalFats = aiMeals.compactMap { $0.fats }.reduce(0, +)
        let totalFiber = aiMeals.compactMap { $0.fiber }.reduce(0, +)
        
        return (totalCarbs, avgCarbs, aiMeals.count, totalProteins, totalFats, totalFiber)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("Desglose Nutricional Completo")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                NutritionalRow(
                    title: "Carbohidratos Totales:",
                    value: "\(Int(nutritionalSummary.carbs))g",
                    color: .orange
                )
                
                NutritionalRow(
                    title: "Proteínas (IA):",
                    value: "\(Int(nutritionalSummary.proteins))g",
                    color: .green
                )
                
                NutritionalRow(
                    title: "Grasas (IA):",
                    value: "\(Int(nutritionalSummary.fats))g",
                    color: .purple
                )
                
                NutritionalRow(
                    title: "Fibra (IA):",
                    value: "\(Int(nutritionalSummary.fiber))g",
                    color: .brown
                )
                
                NutritionalRow(
                    title: "Análisis con IA:",
                    value: "\(nutritionalSummary.aiMeals)/\(meals.count)",
                    color: .blue
                )
                
                if nutritionalSummary.aiMeals > 0 {
                    HStack {
                        Image(systemName: "brain")
                            .foregroundColor(.purple)
                        Text("🎯 \(Int(Double(nutritionalSummary.aiMeals)/Double(meals.count)*100))% de tus comidas analizadas con IA")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - AI Insights Card
struct AIInsightsCard: View {
    let meals: [Meal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.purple)
                Text("Insights de IA")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 12) {
                AIInsightRow(
                    icon: "flame.fill",
                    title: "Promedio de Calorías",
                    value: "\(Int(averageCalories)) kcal",
                    color: .orange,
                    insight: caloriesInsight
                )
                
                AIInsightRow(
                    icon: "figure.strengthtraining.traditional",
                    title: "Balance de Proteínas",
                    value: "\(Int(averageProteins))g",
                    color: .green,
                    insight: proteinsInsight
                )
                
                AIInsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Índice Glucémico",
                    value: dominantGlycemicIndex,
                    color: glycemicColor,
                    insight: glycemicInsight
                )
            }
        }
        .padding()
        .background(LinearGradient(
            gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.05)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var averageCalories: Double {
        let calories = meals.compactMap { $0.calories }
        return calories.isEmpty ? 0 : calories.reduce(0, +) / Double(calories.count)
    }
    
    private var averageProteins: Double {
        let proteins = meals.compactMap { $0.proteins }
        return proteins.isEmpty ? 0 : proteins.reduce(0, +) / Double(proteins.count)
    }
    
    private var dominantGlycemicIndex: String {
        let glycemicCounts = meals.compactMap { $0.glycemicIndex }.reduce(into: [:]) { counts, index in
            counts[index, default: 0] += 1
        }
        
        let dominant = glycemicCounts.max { $0.value < $1.value }?.key ?? .medium
        return "IG \(dominant.rawValue.capitalized)"
    }
    
    private var glycemicColor: Color {
        let glycemicCounts = meals.compactMap { $0.glycemicIndex }.reduce(into: [:]) { counts, index in
            counts[index, default: 0] += 1
        }
        
        let dominant = glycemicCounts.max { $0.value < $1.value }?.key ?? .medium
        switch dominant {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private var caloriesInsight: String {
        switch averageCalories {
        case 0...200: return "Comidas ligeras"
        case 201...400: return "Balance moderado"
        case 401...600: return "Comidas sustanciosas"
        default: return "Comidas abundantes"
        }
    }
    
    private var proteinsInsight: String {
        switch averageProteins {
        case 0...10: return "Bajo en proteínas"
        case 11...20: return "Moderado"
        case 21...30: return "Buen aporte"
        default: return "Alto en proteínas"
        }
    }
    
    private var glycemicInsight: String {
        switch dominantGlycemicIndex {
        case "IG Bajo": return "Excelente control"
        case "IG Medio": return "Balance adecuado"
        default: return "Considera opciones más saludables"
        }
    }
}

// MARK: - Glucose Patterns Card
struct GlucosePatternsCard: View {
    let meals: [Meal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.red)
                Text("Patrones de Glucosa")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if glucoseReadings.isEmpty {
                Text("No hay lecturas de glucosa registradas")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    PatternRow(
                        title: "Promedio General",
                        value: "\(Int(averageGlucose)) mg/dL",
                        color: glucoseColor(for: averageGlucose),
                        trend: glucoseTrend
                    )
                    
                    PatternRow(
                        title: "Rango Normal",
                        value: "\(normalReadingsPercentage)%",
                        color: .green,
                        trend: normalReadingsPercentage > 70 ? "↗" : "↘"
                    )
                    
                    PatternRow(
                        title: "Lecturas Altas",
                        value: "\(highReadingsCount)",
                        color: .red,
                        trend: highReadingsCount > 3 ? "⚠️" : "✓"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var glucoseReadings: [Double] {
        return meals.compactMap { $0.glucoseLevel }
    }
    
    private var averageGlucose: Double {
        return glucoseReadings.isEmpty ? 0 : glucoseReadings.reduce(0, +) / Double(glucoseReadings.count)
    }
    
    private var normalReadingsPercentage: Int {
        let normalReadings = glucoseReadings.filter { $0 >= 70 && $0 <= 140 }.count
        return glucoseReadings.isEmpty ? 0 : Int(Double(normalReadings) / Double(glucoseReadings.count) * 100)
    }
    
    private var highReadingsCount: Int {
        return glucoseReadings.filter { $0 > 140 }.count
    }
    
    private var glucoseTrend: String {
        guard glucoseReadings.count >= 2 else { return "–" }
        let recent = Array(glucoseReadings.suffix(3))
        let older = Array(glucoseReadings.prefix(3))
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)
        
        if recentAvg > olderAvg + 5 {
            return "↗"
        } else if recentAvg < olderAvg - 5 {
            return "↘"
        } else {
            return "→"
        }
    }
    
    private func glucoseColor(for glucose: Double) -> Color {
        switch glucose {
        case 0...70: return .blue
        case 71...99: return .green
        case 100...140: return .orange
        default: return .red
        }
    }
}

// MARK: - Recommendations Card
struct RecommendationsCard: View {
    let meals: [Meal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recomendaciones")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                ForEach(recommendations, id: \.title) { recommendation in
                    RecommendationRow(
                        icon: recommendation.icon,
                        title: recommendation.title,
                        description: recommendation.description,
                        color: recommendation.color
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var recommendations: [Recommendation] {
        var recs: [Recommendation] = []
        
        // Recomendación basada en análisis IA
        let aiMeals = meals.filter { $0.isAIAnalyzed }
        if aiMeals.count < meals.count / 2 {
            recs.append(Recommendation(
                icon: "camera.fill",
                title: "Usa más el análisis IA",
                description: "Obtén información nutricional detallada escaneando tus comidas",
                color: .purple
            ))
        }
        
        // Recomendación basada en glucosa
        let glucoseReadings = meals.compactMap { $0.glucoseLevel }
        let highReadings = glucoseReadings.filter { $0 > 140 }.count
        if highReadings > glucoseReadings.count / 3 {
            recs.append(Recommendation(
                icon: "drop.fill",
                title: "Controla los picos de glucosa",
                description: "Considera alimentos con menor índice glucémico",
                color: .red
            ))
        }
        
        // Recomendación basada en fibra
        let avgFiber = aiMeals.compactMap { $0.fiber }.reduce(0, +) / Double(max(aiMeals.count, 1))
        if avgFiber < 10 {
            recs.append(Recommendation(
                icon: "leaf.fill",
                title: "Aumenta el consumo de fibra",
                description: "Incluye más vegetales, frutas y granos integrales",
                color: .green
            ))
        }
        
        // Recomendación por defecto
        if recs.isEmpty {
            recs.append(Recommendation(
                icon: "checkmark.circle.fill",
                title: "¡Vas por buen camino!",
                description: "Mantén tus hábitos alimenticios actuales",
                color: .green
            ))
        }
        
        return recs
    }
}

// MARK: - Supporting Types and Enums
enum TimeRange: String, CaseIterable {
    case day = "Hoy"
    case week = "Semana"
    case month = "Mes"
    case year = "Año"
    
    var displayName: String { rawValue }
}

enum ChartType: String, CaseIterable, Identifiable {
    case glucose = "Glucosa"
    case carbs = "Carbohidratos"
    case calories = "Calorías"
    case proteins = "Proteínas"
    case fats = "Grasas"
    case fiber = "Fibra"
    case glycemic = "Impacto Glucémico"
    case categories = "Categorías"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .glucose: return "drop.fill"
        case .carbs: return "leaf.fill"
        case .calories: return "flame.fill"
        case .proteins: return "figure.strengthtraining.traditional"
        case .fats: return "drop.circle.fill"
        case .fiber: return "leaf.circle.fill"
        case .glycemic: return "chart.line.uptrend.xyaxis"
        case .categories: return "chart.pie.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .glucose: return .red
        case .carbs: return .orange
        case .calories: return .blue
        case .proteins: return .green
        case .fats: return .purple
        case .fiber: return .brown
        case .glycemic: return .pink
        case .categories: return .cyan
        }
    }
}

struct Recommendation {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Helper Views
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ChartTypeButton: View {
    let chartType: ChartType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: chartType.icon)
                    .font(.caption)
                Text(chartType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? chartType.color : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct NutritionalRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct AIInsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let insight: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(insight)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

struct PatternRow: View {
    let title: String
    let value: String
    let color: Color
    let trend: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            HStack(spacing: 4) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                Text(trend)
                    .font(.caption)
            }
        }
    }
}

struct RecommendationRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EmptyChartView: View {
    let icon: String
    let message: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(color.opacity(0.5))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Chart Data Point
struct ChartDataPoint {
    let date: Date
    let value: Double
    let formattedDate: String
    let color: Color
}

// MARK: - Custom Chart Views (Simplified versions)
struct CustomGlucoseTrendChart: View {
    let meals: [Meal]
    
    var body: some View {
        let glucoseData = meals.compactMap { meal -> ChartDataPoint? in
            guard let glucose = meal.glucoseLevel else { return nil }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM"
            return ChartDataPoint(
                date: meal.date,
                value: glucose,
                formattedDate: dateFormatter.string(from: meal.date),
                color: glucoseColor(for: glucose)
            )
        }
        .sorted { $0.date < $1.date }
        .suffix(10)
        .map { $0 }
        
        if glucoseData.isEmpty {
            EmptyChartView(
                icon: "drop.fill",
                message: "No hay datos de glucosa registrados",
                color: .red
            )
        } else {
            // Implementar gráfica de línea simple
            GeometryReader { geometry in
                let width = geometry.size.width - 60
                let height = geometry.size.height - 40
                let maxValue = glucoseData.map { $0.value }.max() ?? 200
                let minValue = glucoseData.map { $0.value }.min() ?? 70
                
                ZStack {
                    // Líneas de referencia
                    ForEach([70, 100, 140, 180], id: \.self) { value in
                        let y = height - (height * (Double(value) - minValue) / (maxValue - minValue)) + 20
                        Path { path in
                            path.move(to: CGPoint(x: 30, y: y))
                            path.addLine(to: CGPoint(x: width + 30, y: y))
                        }
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    }
                    
                    // Línea de datos
                    if glucoseData.count > 1 {
                        Path { path in
                            for (index, dataPoint) in glucoseData.enumerated() {
                                let x = 30 + (width * CGFloat(index) / CGFloat(glucoseData.count - 1))
                                let normalizedValue = (dataPoint.value - minValue) / (maxValue - minValue)
                                let y = height - (height * normalizedValue) + 20
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.red, lineWidth: 2)
                    }
                    
                    // Puntos de datos
                    ForEach(glucoseData.indices, id: \.self) { index in
                        let dataPoint = glucoseData[index]
                        let x = 30 + (width * CGFloat(index) / CGFloat(max(glucoseData.count - 1, 1)))
                        let normalizedValue = (dataPoint.value - minValue) / (maxValue - minValue)
                        let y = height - (height * normalizedValue) + 20
                        
                        Circle()
                            .fill(dataPoint.color)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }
    
    private func glucoseColor(for glucose: Double) -> Color {
        switch glucose {
        case 0...70: return .blue
        case 71...99: return .green
        case 100...140: return .orange
        default: return .red
        }
    }
}

struct CustomCarbsTrendChart: View {
    let meals: [Meal]
    
    var body: some View {
        let carbsData = meals.compactMap { meal -> ChartDataPoint? in
            guard let carbs = meal.totalCarbs else { return nil }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM"
            return ChartDataPoint(
                date: meal.date,
                value: carbs,
                formattedDate: dateFormatter.string(from: meal.date),
                color: carbsColor(for: carbs)
            )
        }
        .sorted { $0.date < $1.date }
        .suffix(10)
        .map { $0 }
        
        if carbsData.isEmpty {
            EmptyChartView(
                icon: "leaf.fill",
                message: "No hay datos de carbohidratos registrados",
                color: .orange
            )
        } else {
            GeometryReader { geometry in
                let width = geometry.size.width - 60
                let height = geometry.size.height - 40
                let maxValue = carbsData.map { $0.value }.max() ?? 100
                
                HStack(alignment: .bottom, spacing: max(2, width / CGFloat(carbsData.count) - 8)) {
                    ForEach(carbsData.indices, id: \.self) { index in
                        let dataPoint = carbsData[index]
                        let barHeight = (dataPoint.value / maxValue) * height
                        
                        VStack(spacing: 4) {
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(dataPoint.color.gradient)
                                .frame(width: 20, height: barHeight)
                            
                            if index % max(carbsData.count / 4, 1) == 0 {
                                Text(dataPoint.formattedDate)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(-45))
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func carbsColor(for carbs: Double) -> Color {
        switch carbs {
        case 0...20: return .green
        case 21...40: return .yellow
        case 41...60: return .orange
        default: return .red
        }
    }
}

struct CustomCaloriesTrendChart: View {
    let meals: [Meal]
    
    var body: some View {
        let caloriesData = meals.compactMap { meal -> ChartDataPoint? in
            guard let calories = meal.calories, meal.isAIAnalyzed else { return nil }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM"
            return ChartDataPoint(
                date: meal.date,
                value: calories,
                formattedDate: dateFormatter.string(from: meal.date),
                color: caloriesColor(for: calories)
            )
        }
        .sorted { $0.date < $1.date }
        .suffix(10)
        .map { $0 }
        
        if caloriesData.isEmpty {
            EmptyChartView(
                icon: "flame.fill",
                message: "No hay datos de calorías analizadas con IA",
                color: .blue
            )
        } else {
            GeometryReader { geometry in
                let width = geometry.size.width - 60
                let height = geometry.size.height - 40
                let maxValue = caloriesData.map { $0.value }.max() ?? 500
                
                ZStack {
                    // Área bajo la curva
                    if caloriesData.count > 1 {
                        Path { path in
                            let startX: CGFloat = 30
                            let startY = height + 20
                            path.move(to: CGPoint(x: startX, y: startY))
                            
                            for (index, dataPoint) in caloriesData.enumerated() {
                                let x = 30 + (width * CGFloat(index) / CGFloat(caloriesData.count - 1))
                                let normalizedValue = dataPoint.value / maxValue
                                let y = height - (height * normalizedValue) + 20
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            
                            let endX = 30 + width
                            path.addLine(to: CGPoint(x: endX, y: startY))
                            path.closeSubpath()
                        }
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                    }
                    
                    // Línea principal
                    if caloriesData.count > 1 {
                        Path { path in
                            for (index, dataPoint) in caloriesData.enumerated() {
                                let x = 30 + (width * CGFloat(index) / CGFloat(caloriesData.count - 1))
                                let normalizedValue = dataPoint.value / maxValue
                                let y = height - (height * normalizedValue) + 20
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.blue, lineWidth: 2)
                    }
                    
                    // Puntos de datos
                    ForEach(caloriesData.indices, id: \.self) { index in
                        let dataPoint = caloriesData[index]
                        let x = 30 + (width * CGFloat(index) / CGFloat(max(caloriesData.count - 1, 1)))
                        let normalizedValue = dataPoint.value / maxValue
                        let y = height - (height * normalizedValue) + 20
                        
                        Circle()
                            .fill(dataPoint.color)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }
    
    private func caloriesColor(for calories: Double) -> Color {
        switch calories {
        case 0...150: return .green
        case 151...300: return .blue
        case 301...500: return .orange
        default: return .red
        }
    }
}

struct CustomProteinsTrendChart: View {
    let meals: [Meal]
    
    var body: some View {
        let proteinsData = meals.compactMap { meal -> ChartDataPoint? in
            guard let proteins = meal.proteins, meal.isAIAnalyzed else { return nil }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM"
            return ChartDataPoint(
                date: meal.date,
                value: proteins,
                formattedDate: dateFormatter.string(from: meal.date),
                color: proteinsColor(for: proteins)
            )
        }
        .sorted { $0.date < $1.date }
        .suffix(12)
        .map { $0 }
        
        if proteinsData.isEmpty {
            EmptyChartView(
                icon: "figure.strengthtraining.traditional",
                message: "No hay datos de proteínas analizadas con IA",
                color: .green
            )
        } else {
            GeometryReader { geometry in
                let width = geometry.size.width - 60
                let height = geometry.size.height - 40
                let maxValue = proteinsData.map { $0.value }.max() ?? 50
                
                HStack(alignment: .bottom, spacing: max(2, width / CGFloat(proteinsData.count) - 8)) {
                    ForEach(proteinsData.indices, id: \.self) { index in
                        let dataPoint = proteinsData[index]
                        let barHeight = (dataPoint.value / maxValue) * height
                        
                        VStack(spacing: 4) {
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(dataPoint.color.gradient)
                                .frame(width: 20, height: barHeight)
                            
                            if index % max(proteinsData.count / 4, 1) == 0 {
                                Text(dataPoint.formattedDate)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(-45))
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func proteinsColor(for proteins: Double) -> Color {
        switch proteins {
        case 0...10: return .red
        case 11...20: return .orange
        case 21...30: return .green
        default: return .blue
        }
    }
}

struct CustomFatsTrendChart: View {
    let meals: [Meal]
    
    var body: some View {
        let fatsData = meals.compactMap { meal -> ChartDataPoint? in
            guard let fats = meal.fats, meal.isAIAnalyzed else { return nil }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM"
            return ChartDataPoint(
                date: meal.date,
                value: fats,
                formattedDate: dateFormatter.string(from: meal.date),
                color: fatsColor(for: fats)
            )
        }
        .sorted { $0.date < $1.date }
        .suffix(12)
        .map { $0 }
        
        if fatsData.isEmpty {
            EmptyChartView(
                icon: "drop.circle.fill",
                message: "No hay datos de grasas analizadas con IA",
                color: .purple
            )
        } else {
            GeometryReader { geometry in
                let width = geometry.size.width - 60
                let height = geometry.size.height - 40
                
                ZStack {
                    // Área bajo la curva
                    if fatsData.count > 1 {
                        Path { path in
                            let startX: CGFloat = 30
                            let startY = height + 20
                            path.move(to: CGPoint(x: startX, y: startY))
                            
                            for (index, dataPoint) in fatsData.enumerated() {
                                let x = 30 + (width * CGFloat(index) / CGFloat(fatsData.count - 1))
                                let normalizedValue = dataPoint.value / (fatsData.map { $0.value }.max() ?? 30)
                                let y = height - (height * normalizedValue) + 20
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            
                            let endX = 30 + width
                            path.addLine(to: CGPoint(x: endX, y: startY))
                            path.closeSubpath()
                        }
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.1)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                    }
                    
                    // Línea principal
                    if fatsData.count > 1 {
                        Path { path in
                            for (index, dataPoint) in fatsData.enumerated() {
                                let x = 30 + (width * CGFloat(index) / CGFloat(fatsData.count - 1))
                                let normalizedValue = dataPoint.value / (fatsData.map { $0.value }.max() ?? 30)
                                let y = height - (height * normalizedValue) + 20
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.purple, lineWidth: 2)
                    }
                }
            }
        }
    }
    
    private func fatsColor(for fats: Double) -> Color {
        switch fats {
        case 0...5: return .green
        case 6...15: return .yellow
        case 16...25: return .orange
        default: return .red
        }
    }
}

struct CustomFiberTrendChart: View {
    let meals: [Meal]
    
    var body: some View {
        let fiberData = meals.compactMap { meal -> ChartDataPoint? in
            guard let fiber = meal.fiber, meal.isAIAnalyzed else { return nil }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM"
            return ChartDataPoint(
                date: meal.date,
                value: fiber,
                formattedDate: dateFormatter.string(from: meal.date),
                color: fiberColor(for: fiber)
            )
        }
        .sorted { $0.date < $1.date }
        .suffix(12)
        .map { $0 }
        
        if fiberData.isEmpty {
            EmptyChartView(
                icon: "leaf.circle.fill",
                message: "No hay datos de fibra analizadas con IA",
                color: .brown
            )
        } else {
            GeometryReader { geometry in
                let width = geometry.size.width - 60
                let height = geometry.size.height - 40
                let maxValue = fiberData.map { $0.value }.max() ?? 15
                
                HStack(alignment: .bottom, spacing: max(2, width / CGFloat(fiberData.count) - 8)) {
                    ForEach(fiberData.indices, id: \.self) { index in
                        let dataPoint = fiberData[index]
                        let barHeight = (dataPoint.value / maxValue) * height
                        
                        VStack(spacing: 4) {
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(dataPoint.color.gradient)
                                .frame(width: 20, height: barHeight)
                            
                            if index % max(fiberData.count / 4, 1) == 0 {
                                Text(dataPoint.formattedDate)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(-45))
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func fiberColor(for fiber: Double) -> Color {
        switch fiber {
        case 0...2: return .red
        case 3...5: return .orange
        case 6...10: return .green
        default: return .blue
        }
    }
}

struct CustomGlycemicImpactChart: View {
    let meals: [Meal]
    
    var body: some View {
        let glycemicCounts = meals.compactMap { $0.glycemicIndex }.reduce(into: [:]) { counts, index in
            counts[index, default: 0] += 1
        }
        
        if glycemicCounts.isEmpty {
            EmptyChartView(
                icon: "chart.line.uptrend.xyaxis",
                message: "No hay datos de índice glucémico",
                color: .pink
            )
        } else {
            VStack(spacing: 16) {
                ForEach(GlycemicIndex.allCases, id: \.self) { index in
                    let count = glycemicCounts[index] ?? 0
                    let percentage = Double(count) / Double(meals.count) * 100
                    
                    HStack {
                        Text("IG \(index.rawValue.capitalized)")
                            .font(.subheadline)
                            .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 20)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(glycemicColor(for: index))
                                    .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 20)
                            }
                        }
                        .frame(height: 20)
                        
                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
            .padding()
        }
    }
    
    private func glycemicColor(for index: GlycemicIndex) -> Color {
        switch index {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct CustomFoodCategoriesChart: View {
    let meals: [Meal]
    
    var body: some View {
        let categoryCounts = meals.reduce(into: [:]) { counts, meal in
            counts[meal.type, default: 0] += 1
        }
        
        if categoryCounts.isEmpty {
            EmptyChartView(
                icon: "chart.pie.fill",
                message: "No hay datos de categorías",
                color: .cyan
            )
        } else {
            VStack(spacing: 16) {
                ForEach([MealType.breakfast, .lunch, .dinner, .snack], id: \.self) { type in
                    let count = categoryCounts[type] ?? 0
                    let percentage = Double(count) / Double(meals.count) * 100
                    
                    HStack {
                        Image(systemName: mealTypeIcon(for: type))
                            .foregroundColor(mealTypeColor(for: type))
                            .frame(width: 20)
                        
                        Text(type.displayName)
                            .font(.subheadline)
                            .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 20)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(mealTypeColor(for: type))
                                    .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 20)
                            }
                        }
                        .frame(height: 20)
                        
                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
            .padding()
        }
    }
    
    private func mealTypeIcon(for type: MealType) -> String {
        switch type {
        case .breakfast: return "sun.rise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        }
    }
    
    private func mealTypeColor(for type: MealType) -> Color {
        switch type {
        case .breakfast: return .orange
        case .lunch: return .blue
        case .dinner: return .purple
        case .snack: return .green
        }
    }
}

// MARK: - Detail Views
struct DetailedInsightsView: View {
    let meals: [Meal]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Análisis Detallado")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                    
                    // Contenido detallado aquí
                    Text("Próximamente: Análisis detallado de patrones alimenticios")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationTitle("Detalles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // filepath: /Users/alumno/Documents/data_insights/ControlGlucosa/ControlGlucosa/view/InsightsView.swift
                import SwiftUI
                
                // MARK: - Main Insights View
                struct InsightsView: View {
                    @EnvironmentObject var meals: Meals
                    @EnvironmentObject var userProfiles: UserProfiles
                    @State private var selectedTimeRange: TimeRange = .week
                    @State private var selectedChartType: ChartType = .glucose
                    @State private var showingDetailView = false
                    
                    var body: some View {
                        NavigationView {
                            ScrollView {
                                LazyVStack(spacing: 20) {
                                    // Header con selector de tiempo
                                    TimeRangeSelector(selectedTimeRange: $selectedTimeRange)
                                    
                                    // Métricas principales
                                    MainMetricsCard(meals: filteredMeals)
                                    
                                    // Gráfica principal con selector de tipo
                                    EnhancedTrendsAnalysisCard(
                                        meals: filteredMeals,
                                        timeRange: selectedTimeRange
                                    )
                                    
                                    // Desglose nutricional
                                    NutritionalBreakdownCard(meals: filteredMeals)
                                    
                                    // Insights de IA
                                    if hasAIAnalyzedMeals {
                                        AIInsightsCard(meals: aiAnalyzedMeals)
                                    }
                                    
                                    // Patrones de glucosa
                                    GlucosePatternsCard(meals: filteredMeals)
                                    
                                    // Recomendaciones
                                    RecommendationsCard(meals: filteredMeals)
                                }
                                .padding()
                            }
                            .navigationTitle("Insights")
                            .navigationBarTitleDisplayMode(.large)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button(action: { showingDetailView = true }) {
                                        Image(systemName: "info.circle")
                                    }
                                }
                            }
                            .sheet(isPresented: $showingDetailView) {
                                DetailedInsightsView(meals: filteredMeals)
                            }
                        }
                    }
                    
                    // MARK: - Computed Properties
                    private var filteredMeals: [Meal] {
                        let calendar = Calendar.current
                        let now = Date()
                        
                        switch selectedTimeRange {
                        case .day:
                            return meals.meals.filter { calendar.isDate($0.date, inSameDayAs: now) }
                        case .week:
                            return meals.meals.filter {
                                calendar.dateInterval(of: .weekOfYear, for: now)?.contains($0.date) ?? false
                            }
                        case .month:
                            return meals.meals.filter {
                                calendar.dateInterval(of: .month, for: now)?.contains($0.date) ?? false
                            }
                        case .year:
                            return meals.meals.filter {
                                calendar.dateInterval(of: .year, for: now)?.contains($0.date) ?? false
                            }
                        }
                    }
                    
                    private var aiAnalyzedMeals: [Meal] {
                        return filteredMeals.filter { $0.isAIAnalyzed }
                    }
                    
                    private var hasAIAnalyzedMeals: Bool {
                        return !aiAnalyzedMeals.isEmpty
                    }
                }
                
                // MARK: - Time Range Selector
                struct TimeRangeSelector: View {
                    @Binding var selectedTimeRange: TimeRange
                    
                    var body: some View {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Período de Análisis")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Picker("Rango de Tiempo", selection: $selectedTimeRange) {
                                ForEach(TimeRange.allCases, id: \.self) { range in
                                    Text(range.displayName).tag(range)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                
                // MARK: - Main Metrics Card
                struct MainMetricsCard: View {
                    let meals: [Meal]
                    
                    var body: some View {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.blue)
                                Text("Métricas Principales")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                MetricCard(
                                    title: "Comidas Registradas",
                                    value: "\(meals.count)",
                                    subtitle: "total",
                                    color: .blue,
                                    icon: "list.bullet"
                                )
                                
                                MetricCard(
                                    title: "Análisis con IA",
                                    value: "\(aiAnalyzedMeals)",
                                    subtitle: "comidas",
                                    color: .purple,
                                    icon: "brain"
                                )
                                
                                MetricCard(
                                    title: "Glucosa Promedio",
                                    value: averageGlucose > 0 ? "\(Int(averageGlucose))" : "N/A",
                                    subtitle: "mg/dL",
                                    color: glucoseColor,
                                    icon: "drop.fill"
                                )
                                
                                MetricCard(
                                    title: "Calorías IA",
                                    value: "\(Int(totalCaloriesFromAI))",
                                    subtitle: "kcal total",
                                    color: .green,
                                    icon: "flame.fill"
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    
                    private var aiAnalyzedMeals: Int {
                        return meals.filter { $0.isAIAnalyzed }.count
                    }
                    
                    private var totalCaloriesFromAI: Double {
                        return meals.compactMap { $0.calories }.reduce(0, +)
                    }
                    
                    private var averageGlucose: Double {
                        let glucoseValues = meals.compactMap { $0.glucoseLevel }
                        return glucoseValues.isEmpty ? 0 : glucoseValues.reduce(0, +) / Double(glucoseValues.count)
                    }
                    
                    private var glucoseColor: Color {
                        switch averageGlucose {
                        case 0...70: return .blue
                        case 71...99: return .green
                        case 100...140: return .orange
                        default: return .red
                        }
                    }
                }
                
                // MARK: - Enhanced Trends Analysis Card
                struct EnhancedTrendsAnalysisCard: View {
                    let meals: [Meal]
                    let timeRange: TimeRange
                    @State private var selectedChartType: ChartType = .glucose
                    @State private var showingChartDetails = false
                    
                    var body: some View {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "chart.xyaxis.line")
                                    .foregroundColor(.blue)
                                Text("Análisis de Tendencias")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Button(action: { showingChartDetails = true }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            // Selector de tipo de gráfica
                            ChartTypeSelector(selectedChartType: $selectedChartType)
                            
                            // Gráfica dinámica
                            DynamicChartSection()
                            
                            // Estadísticas resumidas
                            SummaryStatsSection()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .sheet(isPresented: $showingChartDetails) {
                            ChartDetailsView(chartType: selectedChartType, meals: meals)
                        }
                    }
                    
                    @ViewBuilder
                    private func ChartTypeSelector(selectedChartType: Binding<ChartType>) -> some View {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ChartType.allCases, id: \.self) { chartType in
                                    ChartTypeButton(
                                        chartType: chartType,
                                        isSelected: selectedChartType.wrappedValue == chartType
                                    ) {
                                        selectedChartType.wrappedValue = chartType
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    @ViewBuilder
                    private func DynamicChartSection() -> some View {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: selectedChartType.icon)
                                    .foregroundColor(selectedChartType.color)
                                Text("Tendencia de \(selectedChartType.rawValue)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(timeRange.rawValue)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(selectedChartType.color.opacity(0.1))
                                    .foregroundColor(selectedChartType.color)
                                    .cornerRadius(8)
                            }
                            
                            Group {
                                switch selectedChartType {
                                case .glucose:
                                    CustomGlucoseTrendChart(meals: meals)
                                case .carbs:
                                    CustomCarbsTrendChart(meals: meals)
                                case .calories:
                                    CustomCaloriesTrendChart(meals: meals)
                                case .proteins:
                                    CustomProteinsTrendChart(meals: meals)
                                case .fats:
                                    CustomFatsTrendChart(meals: meals)
                                case .fiber:
                                    CustomFiberTrendChart(meals: meals)
                                case .glycemic:
                                    CustomGlycemicImpactChart(meals: meals)
                                case .categories:
                                    CustomFoodCategoriesChart(meals: meals)
                                }
                            }
                            .frame(height: 250)
                            .animation(.easeInOut(duration: 0.5), value: selectedChartType)
                        }
                    }
                    
                    @ViewBuilder
                    private func SummaryStatsSection() -> some View {
                        HStack {
                            StatItem(title: summaryStats.title1, value: summaryStats.value1)
                            Spacer()
                            StatItem(title: summaryStats.title2, value: summaryStats.value2)
                            Spacer()
                            StatItem(title: summaryStats.title3, value: summaryStats.value3)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    private var summaryStats: (title1: String, value1: String, title2: String, value2: String, title3: String, value3: String) {
                        let aiMeals = meals.filter { $0.isAIAnalyzed }
                        
                        switch selectedChartType {
                        case .glucose:
                            let glucoseValues = meals.compactMap { $0.glucoseLevel }
                            let avg = glucoseValues.isEmpty ? 0 : glucoseValues.reduce(0, +) / Double(glucoseValues.count)
                            let max = glucoseValues.max() ?? 0
                            let min = glucoseValues.min() ?? 0
                            return ("Promedio", "\(Int(avg)) mg/dL", "Máximo", "\(Int(max)) mg/dL", "Mínimo", "\(Int(min)) mg/dL")
                            
                        case .carbs:
                            let carbValues = meals.compactMap { $0.totalCarbs }
                            let total = carbValues.reduce(0, +)
                            let avg = carbValues.isEmpty ? 0 : total / Double(carbValues.count)
                            let max = carbValues.max() ?? 0
                            return ("Total", "\(Int(total))g", "Promedio", "\(Int(avg))g", "Máximo", "\(Int(max))g")
                            
                        case .calories:
                            let calorieValues = aiMeals.compactMap { $0.calories }
                            let total = calorieValues.reduce(0, +)
                            let avg = calorieValues.isEmpty ? 0 : total / Double(calorieValues.count)
                            let max = calorieValues.max() ?? 0
                            return ("Total", "\(Int(total)) kcal", "Promedio", "\(Int(avg)) kcal", "Máximo", "\(Int(max)) kcal")
                            
                        case .proteins:
                            let proteinValues = aiMeals.compactMap { $0.proteins }
                            let total = proteinValues.reduce(0, +)
                            let avg = proteinValues.isEmpty ? 0 : total / Double(proteinValues.count)
                            let max = proteinValues.max() ?? 0
                            return ("Total", "\(Int(total))g", "Promedio", "\(Int(avg))g", "Máximo", "\(Int(max))g")
                            
                        case .fats:
                            let fatValues = aiMeals.compactMap { $0.fats }
                            let total = fatValues.reduce(0, +)
                            let avg = fatValues.isEmpty ? 0 : total / Double(fatValues.count)
                            let max = fatValues.max() ?? 0
                            return ("Total", "\(Int(total))g", "Promedio", "\(Int(avg))g", "Máximo", "\(Int(max))g")
                            
                        case .fiber:
                            let fiberValues = aiMeals.compactMap { $0.fiber }
                            let total = fiberValues.reduce(0, +)
                            let avg = fiberValues.isEmpty ? 0 : total / Double(fiberValues.count)
                            let max = fiberValues.max() ?? 0
                            return ("Total", "\(Int(total))g", "Promedio", "\(Int(avg))g", "Máximo", "\(Int(max))g")
                            
                        case .glycemic:
                            let lowGI = aiMeals.filter { $0.glycemicIndex == .low }.count
                            let mediumGI = aiMeals.filter { $0.glycemicIndex == .medium }.count
                            let highGI = aiMeals.filter { $0.glycemicIndex == .high }.count
                            return ("IG Bajo", "\(lowGI)", "IG Medio", "\(mediumGI)", "IG Alto", "\(highGI)")
                            
                        case .categories:
                            let breakfast = meals.filter { $0.type == .breakfast }.count
                            let lunch = meals.filter { $0.type == .lunch }.count
                            let dinner = meals.filter { $0.type == .dinner }.count
                            return ("Desayuno", "\(breakfast)", "Almuerzo", "\(lunch)", "Cena", "\(dinner)")
                        }
                    }
                }
                
                // MARK: - Nutritional Breakdown Card
                struct NutritionalBreakdownCard: View {
                    let meals: [Meal]
                    
                    private var nutritionalSummary: (carbs: Double, avgCarbs: Double, aiMeals: Int, proteins: Double, fats: Double, fiber: Double) {
                        let aiMeals = meals.filter { $0.isAIAnalyzed }
                        let carbReadings = meals.compactMap { $0.totalCarbs }
                        let totalCarbs = carbReadings.reduce(0, +)
                        let avgCarbs = carbReadings.isEmpty ? 0 : totalCarbs / Double(carbReadings.count)
                        
                        let totalProteins = aiMeals.compactMap { $0.proteins }.reduce(0, +)
                        let totalFats = aiMeals.compactMap { $0.fats }.reduce(0, +)
                        let totalFiber = aiMeals.compactMap { $0.fiber }.reduce(0, +)
                        
                        return (totalCarbs, avgCarbs, aiMeals.count, totalProteins, totalFats, totalFiber)
                    }
                    
                    var body: some View {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(.green)
                                Text("Desglose Nutricional Completo")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(spacing: 12) {
                                NutritionalRow(
                                    title: "Carbohidratos Totales:",
                                    value: "\(Int(nutritionalSummary.carbs))g",
                                    color: .orange
                                )
                                
                                NutritionalRow(
                                    title: "Proteínas (IA):",
                                    value: "\(Int(nutritionalSummary.proteins))g",
                                    color: .green
                                )
                                
                                NutritionalRow(
                                    title: "Grasas (IA):",
                                    value: "\(Int(nutritionalSummary.fats))g",
                                    color: .purple
                                )
                                
                                NutritionalRow(
                                    title: "Fibra (IA):",
                                    value: "\(Int(nutritionalSummary.fiber))g",
                                    color: .brown
                                )
                                
                                NutritionalRow(
                                    title: "Análisis con IA:",
                                    value: "\(nutritionalSummary.aiMeals)/\(meals.count)",
                                    color: .blue
                                )
                                
                                if nutritionalSummary.aiMeals > 0 {
                                    HStack {
                                        Image(systemName: "brain")
                                            .foregroundColor(.purple)
                                        Text("🎯 \(Int(Double(nutritionalSummary.aiMeals)/Double(meals.count)*100))% de tus comidas analizadas con IA")
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                        Spacer()
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                
                // MARK: - AI Insights Card
                struct AIInsightsCard: View {
                    let meals: [Meal]
                    
                    var body: some View {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "brain")
                                    .foregroundColor(.purple)
                                Text("Insights de IA")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                            }
                            
                            VStack(spacing: 12) {
                                AIInsightRow(
                                    icon: "flame.fill",
                                    title: "Promedio de Calorías",
                                    value: "\(Int(averageCalories)) kcal",
                                    color: .orange,
                                    insight: caloriesInsight
                                )
                                
                                AIInsightRow(
                                    icon: "figure.strengthtraining.traditional",
                                    title: "Balance de Proteínas",
                                    value: "\(Int(averageProteins))g",
                                    color: .green,
                                    insight: proteinsInsight
                                )
                                
                                AIInsightRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Índice Glucémico",
                                    value: dominantGlycemicIndex,
                                    color: glycemicColor,
                                    insight: glycemicInsight
                                )
                            }
                        }
                        .padding()
                        .background(LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    private var averageCalories: Double {
                        let calories = meals.compactMap { $0.calories }
                        return calories.isEmpty ? 0 : calories.reduce(0, +) / Double(calories.count)
                    }
                    
                    private var averageProteins: Double {
                        let proteins = meals.compactMap { $0.proteins }
                        return proteins.isEmpty ? 0 : proteins.reduce(0, +) / Double(proteins.count)
                    }
                    
                    private var dominantGlycemicIndex: String {
                        let glycemicCounts = meals.compactMap { $0.glycemicIndex }.reduce(into: [:]) { counts, index in
                            counts[index, default: 0] += 1
                        }
                        
                        let dominant = glycemicCounts.max { $0.value < $1.value }?.key ?? .medium
                        return "IG \(dominant.rawValue.capitalized)"
                    }
                    
                    private var glycemicColor: Color {
                        let glycemicCounts = meals.compactMap { $0.glycemicIndex }.reduce(into: [:]) { counts, index in
                            counts[index, default: 0] += 1
                        }
                        
                        let dominant = glycemicCounts.max { $0.value < $1.value }?.key ?? .medium
                        switch dominant {
                        case .low: return .green
                        case .medium: return .orange
                        case .high: return .red
                        }
                    }
                    
                    private var caloriesInsight: String {
                        switch averageCalories {
                        case 0...200: return "Comidas ligeras"
                        case 201...400: return "Balance moderado"
                        case 401...600: return "Comidas sustanciosas"
                        default: return "Comidas abundantes"
                        }
                    }
                    
                    private var proteinsInsight: String {
                        switch averageProteins {
                        case 0...10: return "Bajo en proteínas"
                        case 11...20: return "Moderado"
                        case 21...30: return "Buen aporte"
                        default: return "Alto en proteínas"
                        }
                    }
                    
                    private var glycemicInsight: String {
                        switch dominantGlycemicIndex {
                        case "IG Bajo": return "Excelente control"
                        case "IG Medio": return "Balance adecuado"
                        default: return "Considera opciones más saludables"
                        }
                    }
                }
                
                // MARK: - Glucose Patterns Card
                struct GlucosePatternsCard: View {
                    let meals: [Meal]
                    
                    var body: some View {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "waveform.path.ecg")
                                    .foregroundColor(.red)
                                Text("Patrones de Glucosa")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            if glucoseReadings.isEmpty {
                                Text("No hay lecturas de glucosa registradas")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                VStack(spacing: 12) {
                                    PatternRow(
                                        title: "Promedio General",
                                        value: "\(Int(averageGlucose)) mg/dL",
                                        color: glucoseColor(for: averageGlucose),
                                        trend: glucoseTrend
                                    )
                                    
                                    PatternRow(
                                        title: "Rango Normal",
                                        value: "\(normalReadingsPercentage)%",
                                        color: .green,
                                        trend: normalReadingsPercentage > 70 ? "↗" : "↘"
                                    )
                                    
                                    PatternRow(
                                        title: "Lecturas Altas",
                                        value: "\(highReadingsCount)",
                                        color: .red,
                                        trend: highReadingsCount > 3 ? "⚠️" : "✓"
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    
                    private var glucoseReadings: [Double] {
                        return meals.compactMap { $0.glucoseLevel }
                    }
                    
                    private var averageGlucose: Double {
                        return glucoseReadings.isEmpty ? 0 : glucoseReadings.reduce(0, +) / Double(glucoseReadings.count)
                    }
                    
                    private var normalReadingsPercentage: Int {
                        let normalReadings = glucoseReadings.filter { $0 >= 70 && $0 <= 140 }.count
                        return glucoseReadings.isEmpty ? 0 : Int(Double(normalReadings) / Double(glucoseReadings.count) * 100)
                    }
                    
                    private var highReadingsCount: Int {
                        return glucoseReadings.filter { $0 > 140 }.count
                    }
                    
                    private var glucoseTrend: String {
                        guard glucoseReadings.count >= 2 else { return "–" }
                        let recent = Array(glucoseReadings.suffix(3))
                        let older = Array(glucoseReadings.prefix(3))
                        
                        let recentAvg = recent.reduce(0, +) / Double(recent.count)
                        let olderAvg = older.reduce(0, +) / Double(older.count)
                        
                        if recentAvg > olderAvg + 5 {
                            return "↗"
                        } else if recentAvg < olderAvg - 5 {
                            return "↘"
                        } else {
                            return "→"
                        }
                    }
                    
                    private func glucoseColor(for glucose: Double) -> Color {
                        switch glucose {
                        case 0...70: return .blue
                        case 71...99: return .green
                        case 100...140: return .orange
                        default: return .red
                        }
                    }
                }
                
                // MARK: - Recommendations Card
                struct RecommendationsCard: View {
                    let meals: [Meal]
                    
                    var body: some View {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("Recomendaciones")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(recommendations, id: \.title) { recommendation in
                                    RecommendationRow(
                                        icon: recommendation.icon,
                                        title: recommendation.title,
                                        description: recommendation.description,
                                        color: recommendation.color
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    
                    private var recommendations: [Recommendation] {
                        var recs: [Recommendation] = []
                        
                        // Recomendación basada en análisis IA
                        let aiMeals = meals.filter { $0.isAIAnalyzed }
                        if aiMeals.count < meals.count / 2 {
                            recs.append(Recommendation(
                                icon: "camera.fill",
                                title: "Usa más el análisis IA",
                                description: "Obtén información nutricional detallada escaneando tus comidas",
                                color: .purple
                            ))
                        }
                        
                        // Recomendación basada en glucosa
                        let glucoseReadings = meals.compactMap { $0.glucoseLevel }
                        let highReadings = glucoseReadings.filter { $0 > 140 }.count
                        if highReadings > glucoseReadings.count / 3 {
                            recs.append(Recommendation(
                                icon: "drop.fill",
                                title: "Controla los picos de glucosa",
                                description: "Considera alimentos con menor índice glucémico",
                                color: .red
                            ))
                        }
                        
                        // Recomendación basada en fibra
                        let avgFiber = aiMeals.compactMap { $0.fiber }.reduce(0, +) / Double(max(aiMeals.count, 1))
                        if avgFiber < 10 {
                            recs.append(Recommendation(
                                icon: "leaf.fill",
                                title: "Aumenta el consumo de fibra",
                                description: "Incluye más vegetales, frutas y granos integrales",
                                color: .green
                            ))
                        }
                        
                        // Recomendación por defecto
                        if recs.isEmpty {
                            recs.append(Recommendation(
                                icon: "checkmark.circle.fill",
                                title: "¡Vas por buen camino!",
                                description: "Mantén tus hábitos alimenticios actuales",
                                color: .green
                            ))
                        }
                        
                        return recs
                    }
                }
                
                // MARK: - Supporting Types and Enums
                enum TimeRange: String, CaseIterable {
                    case day = "Hoy"
                    case week = "Semana"
                    case month = "Mes"
                    case year = "Año"
                    
                    var displayName: String { rawValue }
                }
                
                enum ChartType: String, CaseIterable, Identifiable {
                    case glucose = "Glucosa"
                    case carbs = "Carbohidratos"
                    case calories = "Calorías"
                    case proteins = "Proteínas"
                    case fats = "Grasas"
                    case fiber = "Fibra"
                    case glycemic = "Impacto Glucémico"
                    case categories = "Categorías"
                    
                    var id: String { rawValue }
                    
                    var icon: String {
                        switch self {
                        case .glucose: return "drop.fill"
                        case .carbs: return "leaf.fill"
                        case .calories: return "flame.fill"
                        case .proteins: return "figure.strengthtraining.traditional"
                        case .fats: return "drop.circle.fill"
                        case .fiber: return "leaf.circle.fill"
                        case .glycemic: return "chart.line.uptrend.xyaxis"
                        case .categories: return "chart.pie.fill"
                        }
                    }
                    
                    var color: Color {
                        switch self {
                        case .glucose: return .red
                        case .carbs: return .orange
                        case .calories: return .blue
                        case .proteins: return .green
                        case .fats: return .purple
                        case .fiber: return .brown
                        case .glycemic: return .pink
                        case .categories: return .cyan
                        }
                    }
                }
                
                struct Recommendation {
                    let icon: String
                    let title: String
                    let description: String
                    let color: Color
                }
                
                // MARK: - Helper Views
                struct MetricCard: View {
                    let title: String
                    let value: String
                    let subtitle: String
                    let color: Color
                    let icon: String
                    
                    var body: some View {
                        VStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(color)
                            
                            Text(value)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(color)
                            
                            Text(title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(color.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                struct ChartTypeButton: View {
                    let chartType: ChartType
                    let isSelected: Bool
                    let action: () -> Void
                    
                    var body: some View {
                        Button(action: action) {
                            HStack(spacing: 6) {
                                Image(systemName: chartType.icon)
                                    .font(.caption)
                                Text(chartType.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? chartType.color : Color(.systemGray6))
                            .foregroundColor(isSelected ? .white : .primary)
                            .cornerRadius(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                struct StatItem: View {
                    let title: String
                    let value: String
                    
                    var body: some View {
                        VStack(spacing: 4) {
                            Text(value)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text(title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                struct NutritionalRow: View {
                    let title: String
                    let value: String
                    let color: Color
                    
                    var body: some View {
                        HStack {
                            Text(title)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(value)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(color)
                        }
                    }
                }
                
                struct AIInsightRow: View {
                    let icon: String
                    let title: String
                    let value: String
                    let color: Color
                    let insight: String
                    
                    var body: some View {
                        HStack(spacing: 12) {
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundColor(color)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(insight)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(value)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(color)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                struct PatternRow: View {
                    let title: String
                    let value: String
                    let color: Color
                    let trend: String
                    
                    var body: some View {
                        HStack {
                            Text(title)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            HStack(spacing: 4) {
                                Text(value)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(color)
                                Text(trend)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                struct RecommendationRow: View {
                    let icon: String
                    let title: String
                    let description: String
                    let color: Color
                    
                    var body: some View {
                        HStack(spacing: 12) {
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundColor(color)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                struct EmptyChartView: View {
                    let icon: String
                    let message: String
                    let color: Color
                    
                    var body: some View {
                        VStack(spacing: 16) {
                            Image(systemName: icon)
                                .font(.system(size: 48))
                                .foregroundColor(color.opacity(0.5))
                            
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                
                // MARK: - Chart Data Point
                struct ChartDataPoint {
                    let date: Date
                    let value: Double
                    let formattedDate: String
                    let color: Color
                }
                
                // MARK: - Custom Chart Views (Simplified versions)
                struct CustomGlucoseTrendChart: View {
                    let meals: [Meal]
                    
                    var body: some View {
                        let glucoseData = meals.compactMap { meal -> ChartDataPoint? in
                            guard let glucose = meal.glucoseLevel else { return nil }
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd/MM"
                            return ChartDataPoint(
                                date: meal.date,
                                value: glucose,
                                formattedDate: dateFormatter.string(from: meal.date),
                                color: glucoseColor(for: glucose)
                            )
                        }
                            .sorted { $0.date < $1.date }
                            .suffix(10)
                            .map { $0 }
                        
                        if glucoseData.isEmpty {
                            EmptyChartView(
                                icon: "drop.fill",
                                message: "No hay datos de glucosa registrados",
                                color: .red
                            )
                        } else {
                            // Implementar gráfica de línea simple
                            GeometryReader { geometry in
                                let width = geometry.size.width - 60
                                let height = geometry.size.height - 40
                                let maxValue = glucoseData.map { $0.value }.max() ?? 200
                                let minValue = glucoseData.map { $0.value }.min() ?? 70
                                
                                ZStack {
                                    // Líneas de referencia
                                    ForEach([70, 100, 140, 180], id: \.self) { value in
                                        let y = height - (height * (Double(value) - minValue) / (maxValue - minValue)) + 20
                                        Path { path in
                                            path.move(to: CGPoint(x: 30, y: y))
                                            path.addLine(to: CGPoint(x: width + 30, y: y))
                                        }
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    }
                                    
                                    // Línea de datos
                                    if glucoseData.count > 1 {
                                        Path { path in
                                            for (index, dataPoint) in glucoseData.enumerated() {
                                                let x = 30 + (width * CGFloat(index) / CGFloat(glucoseData.count - 1))
                                                let normalizedValue = (dataPoint.value - minValue) / (maxValue - minValue)
                                                let y = height - (height * normalizedValue) + 20
                                                
                                                if index == 0 {
                                                    path.move(to: CGPoint(x: x, y: y))
                                                } else {
                                                    path.addLine(to: CGPoint(x: x, y: y))
                                                }
                                            }
                                        }
                                        .stroke(Color.red, lineWidth: 2)
                                    }
                                    
                                    // Puntos de datos
                                    ForEach(glucoseData.indices, id: \.self) { index in
                                        let dataPoint = glucoseData[index]
                                        let x = 30 + (width * CGFloat(index) / CGFloat(max(glucoseData.count - 1, 1)))
                                        let normalizedValue = (dataPoint.value - minValue) / (maxValue - minValue)
                                        let y = height - (height * normalizedValue) + 20
                                        
                                        Circle()
                                            .fill(dataPoint.color)
                                            .frame(width: 8, height: 8)
                                            .position(x: x, y: y)
                                    }
                                }
                            }
                        }
                    }
                    
                    private func glucoseColor(for glucose: Double) -> Color {
                        switch glucose {
                        case 0...70: return .blue
                        case 71...99: return .green
                        case 100...140: return .orange
                        default: return .red
                        }
                    }
                }
                
                struct CustomCarbsTrendChart: View {
                    let meals: [Meal]
                    
                    var body: some View {
                        let carbsData = meals.compactMap { meal -> ChartDataPoint? in
                            guard let carbs = meal.totalCarbs else { return nil }
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd/MM"
                            return ChartDataPoint(
                                date: meal.date,
                                value: carbs,
                                formattedDate: dateFormatter.string(from: meal.date),
                                color: carbsColor(for: carbs)
                            )
                        }
                            .sorted { $0.date < $1.date }
                            .suffix(10)
                            .map { $0 }
                        
                        if carbsData.isEmpty {
                            EmptyChartView(
                                icon: "leaf.fill",
                                message: "No hay datos de carbohidratos registrados",
                                color: .orange
                            )
                        } else {
                            GeometryReader { geometry in
                                let width = geometry.size.width - 60
                                let height = geometry.size.height - 40
                                let maxValue = carbsData.map { $0.value }.max() ?? 100
                                
                                HStack(alignment: .bottom, spacing: max(2, width / CGFloat(carbsData.count) - 8)) {
                                    ForEach(carbsData.indices, id: \.self) { index in
                                        let dataPoint = carbsData[index]
                                        let barHeight = (dataPoint.value / maxValue) * height
                                        
                                        VStack(spacing: 4) {
                                            Spacer()
                                            
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(dataPoint.color.gradient)
                                                .frame(width: 20, height: barHeight)
                                            
                                            if index % max(carbsData.count / 4, 1) == 0 {
                                                Text(dataPoint.formattedDate)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .rotationEffect(.degrees(-45))
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 30)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                    
                    private func carbsColor(for carbs: Double) -> Color {
                        switch carbs {
                        case 0...20: return .green
                        case 21...40: return .yellow
                        case 41...60: return .orange
                        default: return .red
                        }
                    }
                }
                
                struct CustomCaloriesTrendChart: View {
                    let meals: [Meal]
                    
                    var body: some View {
                        let caloriesData = meals.compactMap { meal -> ChartDataPoint? in
                            guard let calories = meal.calories, meal.isAIAnalyzed else { return nil }
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd/MM"
                            return ChartDataPoint(
                                date: meal.date,
                                value: calories,
                                formattedDate: dateFormatter.string(from: meal.date),
                                color: caloriesColor(for: calories)
                            )
                        }
                            .sorted { $0.date < $1.date }
                            .suffix(10)
                            .map { $0 }
                        
                        if caloriesData.isEmpty {
                            EmptyChartView(
                                icon: "flame.fill",
                                message: "No hay datos de calorías analizadas con IA",
                                color: .blue
                            )
                        } else {
                            GeometryReader { geometry in
                                let width = geometry.size.width - 60
                                let height = geometry.size.height - 40
                                let maxValue = caloriesData.map { $0.value }.max() ?? 500
                                
                                ZStack {
                                    // Área bajo la curva
                                    if caloriesData.count > 1 {
                                        Path { path in
                                            let startX: CGFloat = 30
                                            let startY = height + 20
                                            path.move(to: CGPoint(x: startX, y: startY))
                                            
                                            for (index, dataPoint) in caloriesData.enumerated() {
                                                let x = 30 + (width * CGFloat(index) / CGFloat(caloriesData.count - 1))
                                                let normalizedValue = dataPoint.value / maxValue
                                                let y = height - (height * normalizedValue) + 20
                                                path.addLine(to: CGPoint(x: x, y: y))
                                            }
                                            
                                            let endX = 30 + width
                                            path.addLine(to: CGPoint(x: endX, y: startY))
                                            path.closeSubpath()
                                        }
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ))
                                    }
                                    
                                    // Línea principal
                                    if caloriesData.count > 1 {
                                        Path { path in
                                            for (index, dataPoint) in caloriesData.enumerated() {
                                                let x = 30 + (width * CGFloat(index) / CGFloat(caloriesData.count - 1))
                                                let normalizedValue = dataPoint.value / maxValue
                                                let y = height - (height * normalizedValue) + 20
                                                
                                                if index == 0 {
                                                    path.move(to: CGPoint(x: x, y: y))
                                                } else {
                                                    path.addLine(to: CGPoint(x: x, y: y))
                                                }
                                            }
                                        }
                                        .stroke(Color.blue, lineWidth: 2)
                                    }
                                    
                                    // Puntos de datos
                                    ForEach(caloriesData.indices, id: \.self) { index in
                                        let dataPoint = caloriesData[index]
                                        let x = 30 + (width * CGFloat(index) / CGFloat(max(caloriesData.count - 1, 1)))
                                        let normalizedValue = dataPoint.value / maxValue
                                        let y = height - (height * normalizedValue) + 20
                                        
                                        Circle()
                                            .fill(dataPoint.color)
                                            .frame(width: 8, height: 8)
                                            .position(x: x, y: y)
                                    }
                                }
                            }
                        }
                    }
                    
                    private func caloriesColor(for calories: Double) -> Color {
                        switch calories {
                        case 0...150: return .green
                        case 151...300: return .blue
                        case 301...500: return .orange
                        default: return .red
                        }
                    }
                }
            }
        }
    }
}

