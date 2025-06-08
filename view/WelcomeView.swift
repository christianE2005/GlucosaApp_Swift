import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAnimation = false
    @State private var textAnimation = false
    
    var body: some View {
        ZStack {
            // Background gradient sutil
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white,
                    Color.blue.opacity(0.05),
                    Color.blue.opacity(0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo principal con animación
                VStack(spacing: 40) {
                    ZStack {
                        // Círculos de fondo animados
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 180, height: 180)
                            .scaleEffect(showingAnimation ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showingAnimation)
                        
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .scaleEffect(showingAnimation ? 0.9 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showingAnimation)
                        
                        // Ícono principal
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 45))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Texto principal
                    VStack(spacing: 16) {
                        Text("Control de Glucosa")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .opacity(textAnimation ? 1.0 : 0.0)
                            .offset(y: textAnimation ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.3), value: textAnimation)
                        
                        Text("Tu compañero diario para el control de la diabetes")
                            .font(.system(size: 18, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 30)
                            .opacity(textAnimation ? 1.0 : 0.0)
                            .offset(y: textAnimation ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.5), value: textAnimation)
                    }
                }
                
                Spacer()
                
                // Características principales
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        FeatureItem(icon: "chart.line.uptrend.xyaxis", title: "Seguimiento", subtitle: "Registra tus niveles")
                        FeatureItem(icon: "fork.knife", title: "Comidas", subtitle: "Control nutricional")
                        FeatureItem(icon: "bell.fill", title: "Recordatorio", subtitle: "Nunca olvides")
                    }
                    .opacity(textAnimation ? 1.0 : 0.0)
                    .offset(y: textAnimation ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.7), value: textAnimation)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                
                // Botón de inicio
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        appState.navigateToUserSetup()
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Comenzar")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .opacity(textAnimation ? 1.0 : 0.0)
                .offset(y: textAnimation ? 0 : 30)
                .animation(.easeOut(duration: 0.8).delay(0.9), value: textAnimation)
            }
        }
        .onAppear {
            showingAnimation = true
            textAnimation = true
        }
    }
}

// MARK: - Feature Item Component
struct FeatureItem: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
