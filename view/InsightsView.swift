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
                    VStack(spacing: 16) {
                        Picker("Período", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                    }
                    
                    // Métricas principales
                    MetricsOverviewCard(meals: filteredMeals)
                    
                    // Gráfica simplificada
                    SimpleChartCard(meals: filteredMeals, timeRange: selectedTimeRange)
                    
                    // Análisis nutricional
                    NutritionalSummaryCard(meals: filteredMeals)
                    
                    // Patrones identificados
                    PatternsCard(meals: filteredMeals)
                    
                    // Recomendaciones
                    RecommendationsCard(meals: filteredMeals)
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

// MARK: - Time Range
enum TimeRange: String, CaseIterable, Identifiable {
    case week = "7 días"
    case month = "30 días"
    case threeMonths = "3 meses"
    
    var id: String { rawValue }
}

// MARK: - Cards de análisis

struct MetricsOverviewCard: View {
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
                Text("Resumen General")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricItem(
                    title: "Comidas",
                    value: "\(meals.count)",
                    subtitle: "registradas",
                    color: .blue
                )
                
                MetricItem(
                    title: "Glucosa Promedio",
                    value: "\(Int(averageGlucose))",
                    subtitle: "mg/dL",
                    color: glucoseColor
                )
                
                MetricItem(
                    title: "Carbohidratos",
                    value: "\(Int(totalCarbs))",
                    subtitle: "gramos total",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct MetricItem: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SimpleChartCard: View {
    let meals: [Meal]
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Tendencia de Glucosa")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            // Gráfica simplificada con líneas
            VStack(spacing: 12) {
                ForEach(glucoseDataPoints.indices, id: \.self) { index in
                    let dataPoint = glucoseDataPoints[index]
                    HStack {
                        Text(dataPoint.date)
                            .font(.caption)
                            .frame(width: 80, alignment: .leading)
                        
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
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var glucoseDataPoints: [GlucoseDataPoint] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM"
        
        let glucoseMeals = meals.compactMap { meal -> (Date, Double)? in
            guard let glucose = meal.glucoseLevel else { return nil }
            return (meal.date, glucose)
        }.sorted { $0.0 < $1.0 }
        
        let maxValue: Double = 200 // Valor máximo para normalizar
        
        return glucoseMeals.prefix(7).map { date, glucose in
            let normalizedWidth = (glucose / maxValue) * 200 // 200 puntos máximo
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
}

struct GlucoseDataPoint {
    let date: String
    let value: Double
    let width: Double
    let color: Color
}

struct NutritionalSummaryCard: View {
    let meals: [Meal]
    
    private var nutritionalSummary: (carbs: Double, avgCarbs: Double) {
        let carbReadings = meals.compactMap { $0.totalCarbs }
        let totalCarbs = carbReadings.reduce(0, +)
        let avgCarbs = carbReadings.isEmpty ? 0 : totalCarbs / Double(carbReadings.count)
        return (totalCarbs, avgCarbs)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("Análisis Nutricional")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Carbohidratos Totales:")
                    Spacer()
                    Text("\(Int(nutritionalSummary.carbs))g")
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Text("Promedio por Comida:")
                    Spacer()
                    Text("\(Int(nutritionalSummary.avgCarbs))g")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Comidas Registradas:")
                    Spacer()
                    Text("\(meals.count)")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct PatternsCard: View {
    let meals: [Meal]
    
    private var mealTypeDistribution: [(MealType, Int)] {
        let distribution = Dictionary(grouping: meals, by: { $0.type })
        return distribution.map { (type, meals) in
            (type, meals.count)
        }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.purple)
                Text("Patrones Identificados")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                ForEach(mealTypeDistribution, id: \.0) { mealType, count in
                    HStack {
                        Text(mealType.rawValue)
                            .font(.subheadline)
                        
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
                
                if meals.isEmpty {
                    Text("Registra más comidas para ver patrones")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct RecommendationsCard: View {
    let meals: [Meal]
    
    private var recommendations: [String] {
        var recs: [String] = []
        
        let glucoseReadings = meals.compactMap { $0.glucoseLevel }
        let avgGlucose = glucoseReadings.isEmpty ? 0 : glucoseReadings.reduce(0, +) / Double(glucoseReadings.count)
        
        if avgGlucose > 130 {
            recs.append("💡 Tu glucosa promedio está elevada. Considera reducir carbohidratos.")
        } else if avgGlucose < 80 {
            recs.append("⚠️ Tu glucosa promedio está baja. Consulta con tu médico.")
        } else {
            recs.append("✅ Tu glucosa promedio está en rango saludable.")
        }
        
        if meals.count < 5 {
            recs.append("📊 Registra más comidas para obtener insights más precisos.")
        }
        
        let carbReadings = meals.compactMap { $0.totalCarbs }
        let avgCarbs = carbReadings.isEmpty ? 0 : carbReadings.reduce(0, +) / Double(carbReadings.count)
        
        if avgCarbs > 60 {
            recs.append("🥗 Considera aumentar el consumo de verduras y proteínas.")
        }
        
        return recs
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recomendaciones")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(recommendations, id: \.self) { recommendation in
                    Text(recommendation)
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}