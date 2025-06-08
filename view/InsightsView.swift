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
                    
                    // ✨ NUEVA: Análisis de tendencias con gráficas dinámicas
                    EnhancedTrendsAnalysisCard(meals: filteredMeals, timeRange: selectedTimeRange)
                    
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

// MARK: - Enhanced Trends Analysis Card con Gráficas Dinámicas
struct EnhancedTrendsAnalysisCard: View {
    let meals: [Meal]
    let timeRange: TimeRange
    @State private var selectedChartType: ChartType = .glucose
    @State private var showingChartDetails = false
    
    enum ChartType: String, CaseIterable, Identifiable {
        case glucose = "Glucosa"
        case carbs = "Carbohidratos"
        case calories = "Calorías"
        case glycemic = "Impacto Glucémico"
        case categories = "Categorías"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .glucose: return "drop.fill"
            case .carbs: return "leaf.fill"
            case .calories: return "flame.fill"
            case .glycemic: return "chart.line.uptrend.xyaxis"
            case .categories: return "chart.pie.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .glucose: return .red
            case .carbs: return .orange
            case .calories: return .blue
            case .glycemic: return .purple
            case .categories: return .green
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header con selector de gráfica
            ChartHeaderSection()
            
            // Gráfica principal dinámica
            DynamicChartSection()
            
            // Resumen estadístico
            ChartSummarySection()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private func ChartHeaderSection() -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.blue)
                Text("Análisis de Tendencias Dinámico")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Button(action: { showingChartDetails.toggle() }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
            
            // Selector de tipo de gráfica
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ChartType.allCases) { chartType in
                        ChartTypeButton(
                            chartType: chartType,
                            isSelected: selectedChartType == chartType,
                            action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedChartType = chartType
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Dynamic Chart Section
    @ViewBuilder
    private func DynamicChartSection() -> some View {
        VStack(spacing: 16) {
            // Título del gráfico actual
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
            
            // Gráfica dinámica SIN usar Swift Charts (para compatibilidad)
            Group {
                switch selectedChartType {
                case .glucose:
                    CustomGlucoseTrendChart(meals: meals)
                case .carbs:
                    CustomCarbsTrendChart(meals: meals)
                case .calories:
                    CustomCaloriesTrendChart(meals: meals)
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
    
    // MARK: - Chart Summary Section
    @ViewBuilder
    private func ChartSummarySection() -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(.gray)
                Text("Resumen Estadístico")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatSummaryCard(
                    title: summaryStats.title1,
                    value: summaryStats.value1,
                    color: selectedChartType.color
                )
                StatSummaryCard(
                    title: summaryStats.title2,
                    value: summaryStats.value2,
                    color: selectedChartType.color.opacity(0.7)
                )
                StatSummaryCard(
                    title: summaryStats.title3,
                    value: summaryStats.value3,
                    color: selectedChartType.color.opacity(0.4)
                )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Summary Statistics Calculator
    private var summaryStats: (title1: String, value1: String, title2: String, value2: String, title3: String, value3: String) {
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
            let aiMeals = meals.filter { $0.name.hasPrefix("🧠") }
            let totalEstimated = aiMeals.count * 300
            let avgEstimated = aiMeals.isEmpty ? 0 : totalEstimated / aiMeals.count
            return ("Total Est.", "\(totalEstimated) kcal", "Promedio", "\(avgEstimated) kcal", "Comidas IA", "\(aiMeals.count)")
            
        case .glycemic:
            let aiMeals = meals.filter { $0.name.hasPrefix("🧠") }
            let highImpact = aiMeals.filter { meal in
                return meal.name.lowercased().contains("pizza") ||
                       meal.name.lowercased().contains("pasta") ||
                       meal.name.lowercased().contains("pan") ||
                       meal.name.lowercased().contains("arroz")
            }.count
            return ("Alto Impacto", "\(highImpact)", "Bajo Impacto", "\(aiMeals.count - highImpact)", "Total IA", "\(aiMeals.count)")
            
        case .categories:
            let breakfast = meals.filter { $0.type == .breakfast }.count
            let lunch = meals.filter { $0.type == .lunch }.count
            let dinner = meals.filter { $0.type == .dinner }.count
            return ("Desayuno", "\(breakfast)", "Almuerzo", "\(lunch)", "Cena", "\(dinner)")
        }
    }
}

// MARK: - Chart Type Button
struct ChartTypeButton: View {
    let chartType: EnhancedTrendsAnalysisCard.ChartType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: chartType.icon)
                    .font(.caption)
                Text(chartType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? chartType.color : Color.clear
            )
            .foregroundColor(
                isSelected ? .white : chartType.color
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(chartType.color, lineWidth: 1)
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Charts (SIN Swift Charts para compatibilidad)

struct CustomGlucoseTrendChart: View {
    let meals: [Meal]
    
    private var glucoseData: [ChartDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM"
        
        return meals.compactMap { meal -> ChartDataPoint? in
            guard let glucose = meal.glucoseLevel else { return nil }
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
    }
    
    var body: some View {
        if glucoseData.isEmpty {
            EmptyChartView(
                icon: "drop.fill",
                message: "No hay datos de glucosa para mostrar",
                color: .red
            )
        } else {
            VStack(spacing: 12) {
                // Gráfica de líneas personalizada
                GeometryReader { geometry in
                    let width = geometry.size.width - 60
                    let height = geometry.size.height - 40
                    let maxValue = glucoseData.map { $0.value }.max() ?? 200
                    let minValue = max(glucoseData.map { $0.value }.min() ?? 70, 50)
                    
                    ZStack {
                        // Grid lines
                        ForEach(0..<5) { i in
                            let y = height * CGFloat(i) / 4
                            Path { path in
                                path.move(to: CGPoint(x: 30, y: y + 20))
                                path.addLine(to: CGPoint(x: width + 30, y: y + 20))
                            }
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        }
                        
                        // Línea de tendencia
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
                        
                        // Labels Y
                        ForEach(0..<5) { i in
                            let value = minValue + (maxValue - minValue) * Double(4 - i) / 4
                            let y = height * CGFloat(i) / 4 + 20
                            
                            Text("\(Int(value))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .position(x: 15, y: y)
                        }
                        
                        // Labels X
                        ForEach(glucoseData.indices, id: \.self) { index in
                            if index % max(glucoseData.count / 5, 1) == 0 {
                                let dataPoint = glucoseData[index]
                                let x = 30 + (width * CGFloat(index) / CGFloat(max(glucoseData.count - 1, 1)))
                                
                                Text(dataPoint.formattedDate)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(-45))
                                    .position(x: x, y: height + 35)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func glucoseColor(for glucose: Double) -> Color {
        switch glucose {
        case 0...70: return .blue
        case 71...99: return .green
        case 100...125: return .orange
        default: return .red
        }
    }
}

struct CustomCarbsTrendChart: View {
    let meals: [Meal]
    
    private var carbsData: [ChartDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM"
        
        return meals.compactMap { meal -> ChartDataPoint? in
            guard let carbs = meal.totalCarbs else { return nil }
            return ChartDataPoint(
                date: meal.date,
                value: carbs,
                formattedDate: dateFormatter.string(from: meal.date),
                color: carbsColor(for: carbs)
            )
        }
        .sorted { $0.date < $1.date }
        .suffix(12)
        .map { $0 }
    }
    
    var body: some View {
        if carbsData.isEmpty {
            EmptyChartView(
                icon: "leaf.fill",
                message: "No hay datos de carbohidratos",
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
    
    private var caloriesData: [ChartDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM"
        
        let aiMeals = meals.filter { $0.name.hasPrefix("🧠") }
        
        return aiMeals.map { meal -> ChartDataPoint in
            let estimatedCalories = estimateCaloriesFromFoodName(meal.name)
            return ChartDataPoint(
                date: meal.date,
                value: estimatedCalories,
                formattedDate: dateFormatter.string(from: meal.date),
                color: .blue
            )
        }
        .sorted { $0.date < $1.date }
        .suffix(10)
        .map { $0 }
    }
    
    var body: some View {
        if caloriesData.isEmpty {
            EmptyChartView(
                icon: "flame.fill",
                message: "No hay comidas analizadas con IA",
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
                }
            }
        }
    }
    
    private func estimateCaloriesFromFoodName(_ name: String) -> Double {
        let lowercaseName = name.lowercased()
        
        switch true {
        case lowercaseName.contains("ensalada"):
            return 150
        case lowercaseName.contains("pollo"):
            return 250
        case lowercaseName.contains("pizza"):
            return 350
        case lowercaseName.contains("hamburguesa"):
            return 450
        case lowercaseName.contains("pasta"):
            return 300
        case lowercaseName.contains("arroz"):
            return 200
        case lowercaseName.contains("fruta") || lowercaseName.contains("manzana"):
            return 80
        case lowercaseName.contains("verdura"):
            return 50
        case lowercaseName.contains("postre") || lowercaseName.contains("pastel"):
            return 400
        default:
            return 250
        }
    }
}

struct CustomGlycemicImpactChart: View {
    let meals: [Meal]
    
    private var glycemicData: [ChartDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM"
        
        return meals.map { meal -> ChartDataPoint in
            let impact = calculateGlycemicImpact(for: meal)
            return ChartDataPoint(
                date: meal.date,
                value: impact.value,
                formattedDate: dateFormatter.string(from: meal.date),
                color: impact.color
            )
        }
        .sorted { $0.date < $1.date }
        .suffix(10)
        .map { $0 }
    }
    
    var body: some View {
        if glycemicData.isEmpty {
            EmptyChartView(
                icon: "chart.line.uptrend.xyaxis",
                message: "No hay datos de impacto glucémico",
                color: .purple
            )
        } else {
            GeometryReader { geometry in
                let width = geometry.size.width - 60
                let height = geometry.size.height - 40
                
                HStack(alignment: .bottom, spacing: max(2, width / CGFloat(glycemicData.count) - 8)) {
                    ForEach(glycemicData.indices, id: \.self) { index in
                        let dataPoint = glycemicData[index]
                        let barHeight = (dataPoint.value / 25.0) * height
                        
                        VStack(spacing: 4) {
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(dataPoint.color.gradient)
                                .frame(width: 20, height: barHeight)
                            
                            if index % max(glycemicData.count / 4, 1) == 0 {
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
    
    private func calculateGlycemicImpact(for meal: Meal) -> (value: Double, color: Color) {
        let foodName = meal.name.lowercased()
        var impact: Double = 5.0
        
        switch true {
        case foodName.contains("pizza"), foodName.contains("pasta"):
            impact = 18.0
        case foodName.contains("arroz"), foodName.contains("papas"):
            impact = 15.0
        case foodName.contains("hamburguesa"):
            impact = 12.0
        case foodName.contains("pollo"), foodName.contains("carne"):
            impact = 2.0
        case foodName.contains("ensalada"), foodName.contains("verdura"):
            impact = 1.0
        case foodName.contains("fruta"):
            impact = 8.0
        case foodName.contains("postre"), foodName.contains("pastel"):
            impact = 20.0
        default:
            impact = 10.0
        }
        
        if let carbs = meal.totalCarbs {
            impact += carbs * 0.3
        }
        
        let color: Color
        switch impact {
        case 0...7: color = .green
        case 8...15: color = .orange
        default: color = .red
        }
        
        return (min(impact, 25), color)
    }
}

struct CustomFoodCategoriesChart: View {
    let meals: [Meal]
    
    private var categoryData: [(category: String, count: Int, color: Color)] {
        let mealTypeCounts = Dictionary(grouping: meals, by: { $0.type })
            .mapValues { $0.count }
        
        return MealType.allCases.compactMap { mealType in
            let count = mealTypeCounts[mealType] ?? 0
            guard count > 0 else { return nil }
            return (mealType.rawValue, count, mealTypeColor(for: mealType))
        }
    }
    
    var body: some View {
        if categoryData.isEmpty {
            EmptyChartView(
                icon: "chart.pie.fill",
                message: "No hay datos de categorías",
                color: .green
            )
        } else {
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius: CGFloat = min(geometry.size.width, geometry.size.height) / 3
                let total = categoryData.reduce(0) { $0 + $1.count }
                
                ZStack {
                    // Gráfica de dona
                    ForEach(categoryData.indices, id: \.self) { index in
                        let data = categoryData[index]
                        let startAngle = categoryData.prefix(index).reduce(0) { result, item in
                            result + (Double(item.count) / Double(total)) * 360
                        }
                        let endAngle = startAngle + (Double(data.count) / Double(total)) * 360
                        
                        PieSlice(
                            startAngle: Angle(degrees: startAngle),
                            endAngle: Angle(degrees: endAngle),
                            innerRadius: radius * 0.6,
                            outerRadius: radius
                        )
                        .fill(data.color.gradient)
                    }
                    
                    // Centro con información
                    VStack {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(meals.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("comidas")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func mealTypeColor(for mealType: MealType) -> Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .blue
        case .dinner: return .purple
        case .snack: return .green
        }
    }
}

// MARK: - Supporting Views y Data Models

struct EmptyChartView: View {
    let icon: String
    let message: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color.opacity(0.6))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Registra más comidas para ver tendencias")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatSummaryCard: View {
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
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let formattedDate: String
    let color: Color
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        
        return path
    }
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