import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAnimation = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo/Circle Animation
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .scaleEffect(showingAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showingAnimation)
                    
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                
                // Welcome Text
                VStack(spacing: 16) {
                    Text("Control de Glucosa")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Tu compañero para el control diario de la diabetes")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Start Button
                Button(action: {
                    withAnimation(.spring()) {
                        appState.navigateToUserSetup()
                    }
                }) {
                    HStack {
                        Text("Iniciar")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            showingAnimation = true
        }
    }
}