import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var meals: Meals
    @EnvironmentObject var userProfiles: UserProfiles
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Selector de período
                    TimeRangePicker(selectedRange: $selectedTimeRange)
                    
                    // Métricas principales
                    MainMetricsCard(meals: filteredMeals)
                    
                    // Análisis de tendencias
                    TrendsAnalysisCard(meals: filteredMeals, timeRange: selectedTimeRange)
                    
                    // Análisis nutricional
                    NutritionalBreakdownCard(meals: filteredMeals)
                    
                    // Patrones identificados por IA
                    AIInsightsCard(meals: filteredMeals)
                    
                    // Recomendaciones personalizadas
                    PersonalizedRecommendationsCard(meals: filteredMeals, userProfile: userProfiles.currentProfile)
                }
                .padding()
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var filteredMeals: [Meal] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        }
        
        return meals.meals.filter { meal in
            meal.date >= startDate
        }
    }
}

// MARK: - Time Range Picker
struct TimeRangePicker: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Período de Análisis")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Picker("Período", selection: $selectedRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
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

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "7 días"
    case month = "30 días"
    case threeMonths = "3 meses"
    
    var id: String { rawValue }
}

// MARK: - Main Metrics Card
struct MainMetricsCard: View {
    let meals: [Meal]
    
    private var averageGlucose: Double {
        let glucoseReadings = meals.compactMap { $0.glucoseLevel }
        guard !glucoseReadings.isEmpty else { return 0 }
        return glucoseReadings.reduce(0, +) / Double(glucoseReadings.count)
    }
    
    private var totalCarbs: Double {
        let carbReadings = meals.compactMap { $0.totalCarbs }
        return carbReadings.reduce(0, +)
    }
    
    private var aiAnalyzedMeals: Int {
        return meals.filter { $0.name.hasPrefix("🧠") }.count
    }
    
    private var glucoseColor: Color {
        switch averageGlucose {
        case 70...99: return .green
        case 100...125: return .orange
        default: return .red
        }
    }
    
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
                    title: "Carbohidratos",
                    value: "\(Int(totalCarbs))",
                    subtitle: "gramos total",
                    color: .orange,
                    icon: "leaf.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Trends Analysis Card
struct TrendsAnalysisCard: View {
    let meals: [Meal]
    let timeRange: TimeRange
    
    private var glucoseDataPoints: [GlucoseDataPoint] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM"
        
        let glucoseMeals = meals.compactMap { meal -> (Date, Double)? in
            guard let glucose = meal.glucoseLevel else { return nil }
            return (meal.date, glucose)
        }.sorted { $0.0 < $1.0 }
        
        let maxValue: Double = 200
        
        return glucoseMeals.prefix(10).map { date, glucose in
            let normalizedWidth = (glucose / maxValue) * 180
            let color: Color = {
                switch glucose {
                case 70...99: return .green
                case 100...125: return .orange
                default: return .red
                }
            }()
            
            return GlucoseDataPoint(
                date: dateFormatter.string(from: date),
                value: glucose,
                width: normalizedWidth,
                color: color
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Análisis de Tendencias")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if glucoseDataPoints.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Text("No hay suficientes datos de glucosa")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Registra comidas con niveles de glucosa para ver tendencias")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(glucoseDataPoints.indices, id: \.self) { index in
                        let dataPoint = glucoseDataPoints[index]
                        HStack(spacing: 12) {
                            Text(dataPoint.date)
                                .font(.caption)
                                .frame(width: 50, alignment: .leading)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(dataPoint.color)
                                    .frame(width: dataPoint.width, height: 8)
                            }
                            
                            Text("\(Int(dataPoint.value))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(dataPoint.color)
                                .frame(width: 40, alignment: .trailing)
                            
                            Text("mg/dL")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 35, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct GlucoseDataPoint {
    let date: String
    let value: Double
    let width: Double
    let color: Color
}

// MARK: - Nutritional Breakdown Card
struct NutritionalBreakdownCard: View {
    let meals: [Meal]
    
    private var nutritionalSummary: (carbs: Double, avgCarbs: Double, aiMeals: Int) {
        let carbReadings = meals.compactMap { $0.totalCarbs }
        let totalCarbs = carbReadings.reduce(0, +)
        let avgCarbs = carbReadings.isEmpty ? 0 : totalCarbs / Double(carbReadings.count)
        let aiMeals = meals.filter { $0.name.hasPrefix("🧠") }.count
        return (totalCarbs, avgCarbs, aiMeals)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("Desglose Nutricional")
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
                    title: "Promedio por Comida:",
                    value: "\(Int(nutritionalSummary.avgCarbs))g",
                    color: .blue
                )
                
                NutritionalRow(
                    title: "Análisis con IA:",
                    value: "\(nutritionalSummary.aiMeals)/\(meals.count)",
                    color: .purple
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

// MARK: - AI Insights Card
struct AIInsightsCard: View {
    let meals: [Meal]
    
    private var mealTypeDistribution: [(MealType, Int)] {
        let distribution = Dictionary(grouping: meals, by: { $0.type })
        return distribution.map { (type, meals) in
            (type, meals.count)
        }.sorted { $0.1 > $1.1 }
    }
    
    private var aiMealsCount: Int {
        meals.filter { $0.name.hasPrefix("🧠") }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.purple)
                Text("Patrones Identificados por IA")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if meals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Text("Sin datos para analizar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Registra comidas para que la IA identifique patrones")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    if aiMealsCount > 0 {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("IA ha analizado \(aiMealsCount) de tus comidas")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    ForEach(mealTypeDistribution, id: \.0) { mealType, count in
                        HStack {
                            Text(mealType.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(count) comidas")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                    
                    if aiMealsCount == 0 {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .foregroundColor(.blue)
                            Text("Usa la tab 'IA Análisis' para obtener insights automáticos")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Personalized Recommendations Card
struct PersonalizedRecommendationsCard: View {
    let meals: [Meal]
    let userProfile: UserProfile
    
    private var recommendations: [Recommendation] {
        var recs: [Recommendation] = []
        
        let glucoseReadings = meals.compactMap { $0.glucoseLevel }
        let avgGlucose = glucoseReadings.isEmpty ? 0 : glucoseReadings.reduce(0, +) / Double(glucoseReadings.count)
        let aiMealsCount = meals.filter { $0.name.hasPrefix("🧠") }.count
        
        // Recomendaciones basadas en glucosa
        if avgGlucose > 130 {
            recs.append(Recommendation(
                icon: "exclamationmark.triangle.fill",
                title: "Glucosa Elevada",
                description: "Tu glucosa promedio está alta (\(Int(avgGlucose)) mg/dL). Considera reducir carbohidratos.",
                color: .red
            ))
        } else if avgGlucose > 0 && avgGlucose <= 99 {
            recs.append(Recommendation(
                icon: "checkmark.circle.fill",
                title: "Excelente Control",
                description: "Tu glucosa promedio está en rango normal (\(Int(avgGlucose)) mg/dL). ¡Sigue así!",
                color: .green
            ))
        }
        
        // Recomendaciones sobre uso de IA
        if aiMealsCount < meals.count / 2 && meals.count > 5 {
            recs.append(Recommendation(
                icon: "brain",
                title: "Usa Más la IA",
                description: "Solo \(aiMealsCount) de \(meals.count) comidas analizadas con IA. ¡Obtén más insights automáticos!",
                color: .purple
            ))
        }
        
        // Recomendaciones sobre registro
        if meals.count < 10 {
            recs.append(Recommendation(
                icon: "chart.line.uptrend.xyaxis",
                title: "Registra Más Comidas",
                description: "Más datos = mejores insights. Intenta registrar todas tus comidas principales.",
                color: .blue
            ))
        }
        
        // Recomendaciones generales
        let carbReadings = meals.compactMap { $0.totalCarbs }
        let avgCarbs = carbReadings.isEmpty ? 0 : carbReadings.reduce(0, +) / Double(carbReadings.count)
        
        if avgCarbs > 60 {
            recs.append(Recommendation(
                icon: "leaf.fill",
                title: "Considera Más Verduras",
                description: "Promedio de \(Int(avgCarbs))g carbohidratos por comida. Aumenta verduras y proteínas.",
                color: .green
            ))
        }
        
        return recs
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recomendaciones Personalizadas")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if recommendations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    Text("¡Todo se ve bien!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    Text("Continúa registrando comidas para obtener más insights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(recommendations.indices, id: \.self) { index in
                        RecommendationRow(recommendation: recommendations[index])
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct Recommendation {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct RecommendationRow: View {
    let recommendation: Recommendation
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: recommendation.icon)
                .foregroundColor(recommendation.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(recommendation.color.opacity(0.1))
        .cornerRadius(8)
    }
}