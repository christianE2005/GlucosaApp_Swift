import SwiftUI
import UIKit
import AVFoundation

struct FoodAnalysisView: View {
    @EnvironmentObject var meals: Meals
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var analysisResult: FoodAnalysisResult?
    @State private var isAnalyzing = false
    @State private var showingResultSheet = false
    @State private var showingPermissionAlert = false
    
    // Usar el servicio específico Food101
    private let food101Classifier = Food101ClassificationService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header con información de IA
                    VStack(spacing: 20) {
                        // Logo de IA
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 120, height: 120)
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "brain")
                                    .font(.system(size: 35))
                                    .foregroundColor(.white)
                                
                                Text("IA")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        VStack(spacing: 12) {
                            Text("Análisis Nutricional con IA")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text("MobileNetV2 • Food101 Dataset")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                            
                            Text("Inteligencia Artificial entrenada con 101 tipos de alimentos para análisis nutricional específico en diabetes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Sección de imagen y análisis
                    VStack(spacing: 20) {
                        // Imagen seleccionada o placeholder
                        Group {
                            if let selectedImage = selectedImage {
                                VStack(spacing: 16) {
                                    // Imagen con efecto de análisis
                                    ZStack {
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 300, height: 300)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                                        
                                        if isAnalyzing {
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.black.opacity(0.3))
                                                .frame(width: 300, height: 300)
                                            
                                            VStack(spacing: 12) {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(1.5)
                                                
                                                Text("IA Analizando...")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                    .fontWeight(.semibold)
                                                
                                                Text("Clasificando entre 101 alimentos")
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                        }
                                    }
                                    
                                    // Estado del análisis
                                    if isAnalyzing {
                                        VStack(spacing: 8) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "waveform")
                                                    .foregroundColor(.blue)
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Procesando con MobileNetV2")
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.blue)
                                                    Text("Analizando patrones nutricionales...")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                Spacer()
                                            }
                                            .padding()
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            } else {
                                // Placeholder interactivo
                                VStack(spacing: 20) {
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.5)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 2, dash: [10])
                                        )
                                        .frame(width: 300, height: 300)
                                        .overlay(
                                            VStack(spacing: 16) {
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 50))
                                                    .foregroundColor(.blue.opacity(0.7))
                                                
                                                VStack(spacing: 8) {
                                                    Text("Captura tu Comida")
                                                        .font(.headline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.primary)
                                                    
                                                    Text("La IA identificará automáticamente el tipo de alimento y proporcionará análisis nutricional")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                        .multilineTextAlignment(.center)
                                                        .padding(.horizontal, 20)
                                                }
                                            }
                                        )
                                    
                                    // Capacidades de la IA
                                    VStack(spacing: 12) {
                                        Text("🧠 Capacidades de la IA:")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        LazyVGrid(columns: [
                                            GridItem(.flexible()),
                                            GridItem(.flexible())
                                        ], spacing: 8) {
                                            CapabilityBadge(icon: "🍎", text: "101 Alimentos")
                                            CapabilityBadge(icon: "📊", text: "Análisis Nutricional")
                                            CapabilityBadge(icon: "🩺", text: "Insights Diabetes")
                                            CapabilityBadge(icon: "⚡", text: "Análisis Instantáneo")
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Botones de acción
                        VStack(spacing: 16) {
                            if selectedImage == nil {
                                // Botones principales para capturar imagen
                                HStack(spacing: 20) {
                                    // Botón Cámara
                                    Button(action: {
                                        checkCameraPermission { granted in
                                            if granted {
                                                showingCamera = true
                                            } else {
                                                showingPermissionAlert = true
                                            }
                                        }
                                    }) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "camera.fill")
                                                .font(.title2)
                                            Text("Cámara")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("Captura directa")
                                                .font(.caption)
                                                .opacity(0.8)
                                        }
                                        .foregroundColor(.white)
                                        .frame(width: 120, height: 100)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .cornerRadius(16)
                                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                                    }
                                    
                                    // Botón Galería
                                    Button(action: {
                                        showingImagePicker = true
                                    }) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "photo.fill")
                                                .font(.title2)
                                            Text("Galería")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("Foto existente")
                                                .font(.caption)
                                                .opacity(0.8)
                                        }
                                        .foregroundColor(.white)
                                        .frame(width: 120, height: 100)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .cornerRadius(16)
                                        .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                                    }
                                }
                            } else {
                                // Botones de acción para imagen seleccionada
                                VStack(spacing: 12) {
                                    // Botón principal de análisis
                                    Button(action: analyzeFood) {
                                        HStack(spacing: 15) {
                                            if !isAnalyzing {
                                                Image(systemName: "brain")
                                                    .font(.title2)
                                            }
                                            VStack(spacing: 4) {
                                                Text(isAnalyzing ? "Analizando con IA..." : "Analizar con Inteligencia Artificial")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                if !isAnalyzing {
                                                    Text("MobileNetV2 • Precisión del 85%+")
                                                        .font(.caption)
                                                        .opacity(0.9)
                                                }
                                            }
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(16)
                                        .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                                    }
                                    .disabled(isAnalyzing)
                                    .opacity(isAnalyzing ? 0.7 : 1.0)
                                    
                                    // Botón secundario para cambiar imagen
                                    Button(action: {
                                        selectedImage = nil
                                        analysisResult = nil
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "photo.badge.plus")
                                            Text("Cambiar Imagen")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .padding(.vertical, 8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("IA Nutricional")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                selectedImage = image
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                selectedImage = image
            }
        }
        .sheet(isPresented: $showingResultSheet) {
            if let result = analysisResult {
                FoodAnalysisResultView(result: result, originalImage: selectedImage!) {
                    showingResultSheet = false
                    selectedImage = nil
                    analysisResult = nil
                }
            }
        }
        .alert("Permiso de Cámara Requerido", isPresented: $showingPermissionAlert) {
            Button("Configuración") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Para usar la cámara, necesitas habilitar el permiso en Configuración > Control de Glucosa > Cámara")
        }
    }
    
    // MARK: - Análisis con IA Food101
    private func analyzeFood() {
        guard let image = selectedImage else { return }
        
        isAnalyzing = true
        
        Task {
            do {
                print("🧠 Iniciando análisis con IA Food101...")
                let result = try await food101Classifier.classifyFood(image: image)
                
                DispatchQueue.main.async {
                    print("✅ Análisis completado: \(result.foodName)")
                    self.analysisResult = result
                    self.isAnalyzing = false
                    self.showingResultSheet = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    print("❌ Error en análisis Food101: \(error)")
                    
                    // Manejar errores específicos
                    if let food101Error = error as? Food101Error {
                        print("Error específico: \(food101Error.localizedDescription)")
                        // Aquí podrías mostrar una alerta al usuario
                    }
                }
            }
        }
    }
    
    // MARK: - Gestión de permisos de cámara
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}

// MARK: - Componentes auxiliares

struct CapabilityBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Text(icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}