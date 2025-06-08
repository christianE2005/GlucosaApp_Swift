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
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                            
                            Text(userProfiles.currentProfile.name.prefix(1).uppercased())
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text(userProfiles.currentProfile.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("\(userProfiles.currentProfile.age) años • \(userProfiles.currentProfile.diabetesType)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Editar Perfil") {
                            showingEditProfile = true
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Estadísticas del usuario
                    ProfileStatsCard(meals: meals.meals)
                    
                    // Configuraciones
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
                                subtitle: userProfiles.currentProfile.notificationsEnabled ? "Activadas" : "Desactivadas",
                                color: .orange
                            ) {}
                            
                            Divider()
                                .padding(.leading, 44)
                            
                            SettingsRow(
                                icon: "chart.bar.fill",
                                title: "Unidades",
                                subtitle: userProfiles.currentProfile.preferredUnits,
                                color: .green
                            ) {}
                            
                            Divider()
                                .padding(.leading, 44)
                            
                            SettingsRow(
                                icon: "globe",
                                title: "Idioma",
                                subtitle: userProfiles.currentProfile.preferredLanguage,
                                color: .blue
                            ) {}
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Información adicional
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
                                subtitle: "Obtener ayuda",
                                color: .blue
                            ) {}
                            
                            Divider()
                                .padding(.leading, 44)
                            
                            SettingsRow(
                                icon: "doc.text.fill",
                                title: "Privacidad",
                                subtitle: "Política de privacidad",
                                color: .green
                            ) {}
                            
                            Divider()
                                .padding(.leading, 44)
                            
                            SettingsRow(
                                icon: "star.fill",
                                title: "Calificar App",
                                subtitle: "Danos tu opinión",
                                color: .yellow
                            ) {}
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Botón de reset (para desarrollo)
                    Button("Reiniciar App (Desarrollo)") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
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
    
    private func resetApp() {
        userProfiles.resetProfile()
        meals.meals.removeAll()
        appState.resetToWelcome()
    }
}

// MARK: - Components

struct ProfileStatsCard: View {
    let meals: [Meal]
    
    private var weeklyMeals: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return meals.filter { $0.date >= weekAgo }.count
    }
    
    private var averageGlucose: Double {
        let glucoseReadings = meals.compactMap { $0.glucoseLevel }
        guard !glucoseReadings.isEmpty else { return 0 }
        return glucoseReadings.reduce(0, +) / Double(glucoseReadings.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Estadísticas")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Esta Semana",
                    value: "\(weeklyMeals)",
                    subtitle: "comidas",
                    color: .blue
                )
                
                StatItem(
                    title: "Total",
                    value: "\(meals.count)",
                    subtitle: "registros",
                    color: .green
                )
                
                StatItem(
                    title: "Promedio",
                    value: "\(Int(averageGlucose))",
                    subtitle: "mg/dL",
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

struct StatItem: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
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
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
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