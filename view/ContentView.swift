import SwiftUI
import Foundation

struct ContentView: View {
    @EnvironmentObject var meals: Meals
    @EnvironmentObject var userProfiles: UserProfiles
    @EnvironmentObject var appState: AppState
    @State private var showingAddMeal = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header con información del usuario
                if !userProfiles.currentProfile.name.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Hola, \(userProfiles.currentProfile.name)")
                            .font(.title2)
                            .foregroundColor(.primary)
                        
                        Text("Control de Glucosa")
                            .font(.subheadline)
                            .foregroundColor(Color.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                
                // Lista de comidas
                if meals.meals.isEmpty {
                    // Estado vacío
                    VStack(spacing: 20) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 60))
                            .foregroundColor(Color.gray)
                        
                        Text("No hay comidas registradas")
                            .font(.title3)
                            .foregroundColor(Color.gray)
                        
                        Text("Agrega tu primera comida para comenzar a hacer seguimiento")
                            .font(.body)
                            .foregroundColor(Color.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Lista de comidas
                    List {
                        ForEach(meals.meals.sorted(by: { $0.date > $1.date })) { meal in
                            MealRow(meal: meal)
                        }
                        .onDelete(perform: deleteMeals)
                    }
                }
                
                // Botón para agregar comida
                Button(action: {
                    showingAddMeal = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Agregar Comida")
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding()
                .accessibilityLabel("Agregar nueva comida")
            }
            .navigationTitle("Control de Glucosa")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Configuración del Perfil") {
                            appState.navigateToUserSetup()
                        }
                        
                        Button("Reiniciar App (Testing)", role: .destructive) {
                            showingResetAlert = true
                        }
                    } label: {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView()
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
    }
    
    // Función para eliminar comidas
    private func deleteMeals(offsets: IndexSet) {
        let sortedMeals = meals.meals.sorted(by: { $0.date > $1.date })
        for index in offsets {
            meals.deleteMeal(sortedMeals[index])
        }
    }
    
    // Función para resetear la app
    private func resetApp() {
        // Borrar todos los datos
        userProfiles.resetProfile()
        meals.meals.removeAll()
        
        // Volver a la pantalla de bienvenida
        appState.resetToWelcome()
    }
}
