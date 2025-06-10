import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userProfiles: UserProfiles
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var meals: Meals
    @State private var showingResetAlert = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header del perfil
                    ProfileHeaderCard()
                    
                    // Estadísticas del usuario
                    UserStatsCard()
                    
                    // Configuraciones de la app
                    AppSettingsCard()
                    
                    // Información y soporte
                    SupportInfoCard()
                    
                    // Botón de desarrollo (reset)
                    DeveloperActionsCard()
                }
                .padding()
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingEditProfile) {
            UserSetupView()
        }
        .alert("Reiniciar Aplicación", isPresented: $showingResetAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Reiniciar", role: .destructive) {
                resetApp()
            }
        } message: {
            Text("Esto borrará todos los datos y te llevará al registro inicial. ¿Estás seguro?")
        }
    }
    
    // MARK: - Header del perfil
    @ViewBuilder
    private func ProfileHeaderCard() -> some View {
        VStack(spacing: 16) {
            // Avatar y nombre
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text((userProfiles.currentProfile?.name ?? "U").prefix(1).uppercased())
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text(userProfiles.currentProfile?.name.isEmpty == false ? userProfiles.currentProfile?.name ?? "Usuario" : "Usuario")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let age = userProfiles.currentProfile?.age, age > 0 {
                        Text("\(age) años")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let diabetesType = userProfiles.currentProfile?.diabetesType, !diabetesType.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.text.square")
                                .foregroundColor(.red)
                            Text(diabetesType)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            // Botón editar perfil
            Button("Editar Perfil") {
                showingEditProfile = true
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Estadísticas del usuario
    @ViewBuilder
    private func UserStatsCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Estadísticas")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Esta Semana",
                    value: "\(weeklyMeals)",
                    subtitle: "comidas",
                    color: .blue,
                    icon: "calendar"
                )
                
                StatCard(
                    title: "Total",
                    value: "\(meals.meals.count)",
                    subtitle: "registros",
                    color: .green,
                    icon: "list.bullet.clipboard"
                )
                
                StatCard(
                    title: "Promedio",
                    value: "\(Int(averageGlucose))",
                    subtitle: "mg/dL",
                    color: glucoseColor,
                    icon: "drop.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Configuraciones de la app
    @ViewBuilder
    private func AppSettingsCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(.gray)
                Text("Configuración")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notificaciones",
                    subtitle: (userProfiles.currentProfile?.notificationsEnabled ?? false) ? "Activadas" : "Desactivadas",
                    color: .orange
                ) {
                    // Acción para notificaciones
                }
                
                Divider().padding(.leading, 44)
                
                SettingsRow(
                    icon: "chart.bar.fill",
                    title: "Unidades",
                    subtitle: userProfiles.currentProfile?.preferredUnits ?? "mg/dL",
                    color: .green
                ) {
                    // Acción para unidades
                }
                
                Divider().padding(.leading, 44)
                
                SettingsRow(
                    icon: "brain",
                    title: "Modelo de IA",
                    subtitle: "MobileNetV2 Food101",
                    color: .purple
                ) {
                    // Información del modelo
                }
                
                Divider().padding(.leading, 44)
                
                SettingsRow(
                    icon: "globe",
                    title: "Idioma",
                    subtitle: userProfiles.currentProfile?.preferredLanguage ?? "Español",
                    color: .blue
                ) {
                    // Acción para idioma
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Información y soporte
    @ViewBuilder
    private func SupportInfoCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Información")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Ayuda y Soporte",
                    subtitle: "Cómo usar la app",
                    color: .blue
                ) {
                    // Acción para ayuda
                }
                
                Divider().padding(.leading, 44)
                
                SettingsRow(
                    icon: "doc.text.fill",
                    title: "Acerca del Modelo IA",
                    subtitle: "Food101 Dataset",
                    color: .purple
                ) {
                    // Información del modelo
                }
                
                Divider().padding(.leading, 44)
                
                SettingsRow(
                    icon: "heart.fill",
                    title: "Sobre Diabetes",
                    subtitle: "Recursos educativos",
                    color: .red
                ) {
                    // Recursos sobre diabetes
                }
                
                Divider().padding(.leading, 44)
                
                SettingsRow(
                    icon: "star.fill",
                    title: "Calificar App",
                    subtitle: "Tu opinión nos ayuda",
                    color: .yellow
                ) {
                    // Acción para calificar
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Acciones de desarrollo
    @ViewBuilder
    private func DeveloperActionsCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wrench.and.screwdriver")
                    .foregroundColor(.orange)
                Text("Desarrollo")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Button("Reiniciar App (Testing)") {
                showingResetAlert = true
            }
            .font(.subheadline)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
            
            Text("⚠️ Solo para desarrollo. Borra todos los datos.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Cálculos de estadísticas
    private var weeklyMeals: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return meals.meals.filter { $0.date >= weekAgo }.count
    }
    
    private var averageGlucose: Double {
        let glucoseReadings = meals.meals.compactMap { $0.glucoseLevel }
        guard !glucoseReadings.isEmpty else { return 0 }
        return glucoseReadings.reduce(0, +) / Double(glucoseReadings.count)
    }
    
    private var glucoseColor: Color {
        switch averageGlucose {
        case 70...99: return .green
        case 100...125: return .orange
        default: return .red
        }
    }
    
    private func resetApp() {
        userProfiles.resetProfile()
        meals.meals.removeAll()
        appState.resetToWelcome()
    }
}

// MARK: - Componentes auxiliares

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
