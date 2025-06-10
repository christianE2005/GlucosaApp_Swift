import SwiftUI

struct MainTabView: View {
    // MARK: - Environment Objects
    @StateObject private var meals = Meals()
    @StateObject private var userProfiles = UserProfiles()
    @StateObject private var appState = AppState()
    
    var body: some View {
        TabView {
            // Tab 1: Lista de Comidas
            MealsListTabView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Comidas")
                }
                .environmentObject(meals)
                .environmentObject(userProfiles)
                .environmentObject(appState)
            
            // Tab 2: Computer Vision con IA
            FoodAnalysisView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Análisis IA")
                }
                .environmentObject(meals)
                .environmentObject(userProfiles)
                .environmentObject(appState)
            
            // Tab 3: Gráficas e Insights
            InsightsView()
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Insights")
                }
                .environmentObject(meals)
                .environmentObject(userProfiles)
                .environmentObject(appState)
            
            // Tab 4: Perfil de Usuario
            UserProfileTabView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Perfil")
                }
                .environmentObject(meals)
                .environmentObject(userProfiles)
                .environmentObject(appState)
        }
        .accentColor(.blue)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    // MARK: - Configuración de apariencia del TabBar
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Configuración para ítems normales
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        
        // Configuración para ítems seleccionados
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Tab Views

struct MealsListTabView: View {
    @EnvironmentObject var userProfiles: UserProfiles
    @State private var showingAddMeal = false
    
    var body: some View {
        NavigationView {
            VStack {
                if meals.meals.isEmpty {
                    EmptyMealsView()
                } else {
                    MealsListView()
                }
            }
            .navigationTitle("Mis Comidas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMeal = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView()
                    .environmentObject(meals)
            }
        }
    }
}

struct EmptyMealsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No hay comidas registradas")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Agrega tu primera comida tocando el botón + o usa el análisis con IA")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Agregar Comida Manual")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Usar Análisis IA")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
}

struct MealsListView: View {
    @EnvironmentObject var meals: Meals
    
    var body: some View {
        List {
            ForEach(groupedMealsByDate, id: \.key) { dateGroup in
                Section(header: DateSectionHeader(date: dateGroup.key)) {
                    ForEach(dateGroup.value) { meal in
                        MealRowView(meal: meal)
                    }
                    .onDelete { indexSet in
                        deleteMeals(at: indexSet, from: dateGroup.value)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var groupedMealsByDate: [(key: Date, value: [Meal])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: meals.meals) { meal in
            calendar.startOfDay(for: meal.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func deleteMeals(at indexSet: IndexSet, from mealsArray: [Meal]) {
        for index in indexSet {
            let mealToDelete = mealsArray[index]
            if let mealIndex = meals.meals.firstIndex(where: { $0.id == mealToDelete.id }) {
                meals.meals.remove(at: mealIndex)
            }
        }
    }
}

struct DateSectionHeader: View {
    let date: Date
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }
    
    var body: some View {
        Text(dateFormatter.string(from: date))
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }
}

struct MealRowView: View {
    let meal: Meal
    
    var body: some View {
        HStack(spacing: 12) {
            // Icono del tipo de comida
            Image(systemName: mealTypeIcon(for: meal.type))
                .font(.title2)
                .foregroundColor(mealTypeColor(for: meal.type))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(meal.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let carbs = meal.totalCarbs {
                    Text("Carbohidratos: \(Int(carbs))g")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if meal.isAIAnalyzed, let calories = meal.calories {
                    Text("Calorías: \(Int(calories)) kcal")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if meal.isAIAnalyzed {
                    HStack(spacing: 4) {
                        Image(systemName: "brain")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text("IA")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
                
                if let glucose = meal.glucoseLevel {
                    Text("\(Int(glucose)) mg/dL")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(glucoseColor(for: glucose))
                }
                
                Text(timeFormatter.string(from: meal.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
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
    
    private func glucoseColor(for glucose: Double) -> Color {
        switch glucose {
        case 0...70: return .blue
        case 71...99: return .green
        case 100...140: return .orange
        default: return .red
        }
    }
}

struct AddMealView: View {
    @EnvironmentObject var meals: Meals
    @Environment(\.presentationMode) var presentationMode
    
    @State private var mealName = ""
    @State private var selectedType: MealType = .breakfast
    @State private var carbs = ""
    @State private var glucose = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información Básica")) {
                    TextField("Nombre de la comida", text: $mealName)
                    
                    Picker("Tipo de comida", selection: $selectedType) {
                        ForEach([MealType.breakfast, .lunch, .dinner, .snack], id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Información Nutricional (Opcional)")) {
                    TextField("Carbohidratos (g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    
                    TextField("Nivel de glucosa (mg/dL)", text: $glucose)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Nueva Comida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveMeal()
                    }
                    .disabled(mealName.isEmpty)
                }
            }
        }
    }
    
    private func saveMeal() {
        let newMeal = Meal(
            name: mealName,
            type: selectedType,
            portions: [],
            timestamp: Date(),
            totalCarbs: Double(carbs),
            glucoseLevel: Double(glucose),
            date: Date(),
            isAIAnalyzed: false
        )
        
        meals.addMeal(newMeal)
        presentationMode.wrappedValue.dismiss()
    }
}

struct UserProfileTabView: View {
    @EnvironmentObject var userProfiles: UserProfiles
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let profile = userProfiles.currentProfile {
                    ProfileInfoView(profile: profile)
                } else {
                    NoProfileView()
                }
                
                Spacer()
                
                Button("Cerrar Sesión") {
                    // Implementar lógica de cierre de sesión
                    print("Cerrando sesión...")
                }
                .foregroundColor(.red)
                .padding()
            }
            .padding()
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ProfileInfoView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(profile.name)
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                ProfileRowView(title: "Edad", value: "\(profile.age) años")
                ProfileRowView(title: "Peso", value: "\(Int(profile.weight)) kg")
                ProfileRowView(title: "Altura", value: "\(Int(profile.height)) cm")
            }
        }
        .padding()
    }
}

struct ProfileRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct NoProfileView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No hay perfil configurado")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Button("Crear Perfil") {
                // Implementar navegación a creación de perfil
                print("Crear perfil...")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}