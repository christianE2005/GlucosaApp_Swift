import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var meals: Meals
    @EnvironmentObject var userProfiles: UserProfiles
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            // Tab 1: Lista de Comidas
            ContentView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Comidas")
                }
            
            // Tab 2: Computer Vision (¡NUEVA FUNCIONALIDAD!)
            FoodAnalysisView()
                .tabItem {
                    Image(systemName: "camera.viewfinder")
                    Text("IA Análisis")
                }
            
            // Tab 3: Insights y Gráficas
            InsightsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Insights")
                }
            
            // Tab 4: Perfil del Usuario
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Perfil")
                }
        }
        .accentColor(.blue)
        .onAppear {
            // Configurar apariencia de la tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}