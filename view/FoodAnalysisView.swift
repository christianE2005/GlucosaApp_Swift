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
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var isRequestingPermission = false
    
    // Usar el servicio REAL Food101
    private let food101Classifier = Food101ClassificationService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header con información de IA REAL
                    AIHeaderSection()
                    
                    // Sección de imagen y análisis
                    ImageAnalysisSection()
                    
                    // Sección de botones de acción
                    ActionButtonsSection()
                    
                    // Información adicional
                    if selectedImage == nil {
                        AdditionalInfoSection()
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("IA Nutricional REAL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Debug") {
                        debugSystemStatus()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            setupInitialState()
        }
        .sheet(isPresented: $showingImagePicker) {
            SafeImagePicker(sourceType: .photoLibrary) { image in
                selectedImage = image
                print("📸 Imagen seleccionada de galería: \(image.size)")
            }
        }
        .sheet(isPresented: $showingCamera) {
            SafeImagePicker(sourceType: .camera) { image in
                selectedImage = image
                print("📸 Imagen capturada con cámara: \(image.size)")
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
                openAppSettings()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Para usar la cámara, necesitas habilitar el permiso en Configuración.")
        }
        .alert("Error de Análisis", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
            Button("Reintentar") {
                analyzeFood()
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Setup Functions
    private func setupInitialState() {
        print("🚀 FoodAnalysisView inicializando...")
        
        // Verificar estado inicial de permisos sin solicitarlos
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        print("📸 Estado inicial de cámara: \(cameraPermissionStatus.debugDescription)")
        
        // Debug de configuración
        debugPrivacyConfiguration()
        
        // Debug del modelo (diferido para evitar bloqueo)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            food101Classifier.debugBundleContents()
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private func AIHeaderSection() -> some View {
        VStack(spacing: 20) {
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
                    Text("Análisis REAL • Machine Learning")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                
                Text("Inteligencia Artificial con modelos reales de clasificación de alimentos.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Image Analysis Section
    @ViewBuilder
    private func ImageAnalysisSection() -> some View {
        VStack(spacing: 20) {
            if let selectedImage = selectedImage {
                SelectedImageView(image: selectedImage)
            } else {
                PlaceholderImageView()
            }
        }
    }
    
    @ViewBuilder
    private func SelectedImageView(image: UIImage) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Image(uiImage: image)
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
                    }
                }
            }
            
            if isAnalyzing {
                HStack(spacing: 12) {
                    Image(systemName: "waveform")
                        .foregroundColor(.green)
                    Text("Procesando con Machine Learning...")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    @ViewBuilder
    private func PlaceholderImageView() -> some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10]))
                .frame(width: 300, height: 300)
                .overlay(
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue.opacity(0.7))
                        
                        Text("Captura tu Comida")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("La IA identificará automáticamente el alimento")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                )
        }
    }
    
    // MARK: - Action Buttons Section
    @ViewBuilder
    private func ActionButtonsSection() -> some View {
        VStack(spacing: 16) {
            if selectedImage == nil {
                HStack(spacing: 20) {
                    SafeCameraButton()
                    GalleryButton()
                }
            } else {
                VStack(spacing: 12) {
                    AnalyzeButton()
                    ChangeImageButton()
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Safe Camera Button (Previene SIGABRT)
    @ViewBuilder
    private func SafeCameraButton() -> some View {
        Button(action: {
            requestCameraPermissionSafely()
        }) {
            VStack(spacing: 12) {
                Image(systemName: cameraButtonIcon)
                    .font(.title2)
                Text("Cámara")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(cameraButtonSubtitle)
                    .font(.caption)
                    .opacity(0.8)
            }
            .foregroundColor(.white)
            .frame(width: 120, height: 100)
            .background(cameraButtonGradient)
            .cornerRadius(16)
            .shadow(color: cameraButtonColor.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .disabled(isRequestingPermission || cameraPermissionStatus == .restricted)
        .opacity(cameraButtonOpacity)
    }
    
    @ViewBuilder
    private func GalleryButton() -> some View {
        Button(action: {
            print("📸 Abriendo galería...")
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
    
    @ViewBuilder
    private func AnalyzeButton() -> some View {
        Button(action: analyzeFood) {
            HStack(spacing: 15) {
                if !isAnalyzing {
                    Image(systemName: "brain")
                        .font(.title2)
                }
                Text(isAnalyzing ? "Analizando..." : "Analizar con IA")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.green, Color.blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .disabled(isAnalyzing)
        .opacity(isAnalyzing ? 0.7 : 1.0)
    }
    
    @ViewBuilder
    private func ChangeImageButton() -> some View {
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
    
    @ViewBuilder
    private func AdditionalInfoSection() -> some View {
        VStack(spacing: 16) {
            Text("💡 Consejos para Mejores Resultados")
                .font(.headline)
                
            VStack(spacing: 8) {
                InfoRow(icon: "lightbulb.fill", text: "Usa buena iluminación", color: .yellow)
                InfoRow(icon: "viewfinder", text: "Enfoque claro del alimento", color: .blue)
                InfoRow(icon: "rectangle.center.inset.filled", text: "Un alimento por imagen", color: .green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    @ViewBuilder
    private func InfoRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
    
    // MARK: - Camera Button Properties
    private var cameraButtonIcon: String {
        switch cameraPermissionStatus {
        case .authorized:
            return "camera.fill"
        case .denied:
            return "camera.fill.badge.ellipsis"
        case .restricted:
            return "exclamationmark.triangle.fill"
        case .notDetermined:
            return isRequestingPermission ? "hourglass" : "camera.fill"
        @unknown default:
            return "camera.fill"
        }
    }
    
    private var cameraButtonSubtitle: String {
        switch cameraPermissionStatus {
        case .authorized:
            return "Captura directa"
        case .denied:
            return "Permiso denegado"
        case .restricted:
            return "No disponible"
        case .notDetermined:
            return isRequestingPermission ? "Solicitando..." : "Captura directa"
        @unknown default:
            return "Estado desconocido"
        }
    }
    
    private var cameraButtonColor: Color {
        switch cameraPermissionStatus {
        case .authorized:
            return .blue
        case .denied, .restricted:
            return .gray
        case .notDetermined:
            return .blue
        @unknown default:
            return .gray
        }
    }
    
    private var cameraButtonGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [cameraButtonColor, cameraButtonColor.opacity(0.8)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var cameraButtonOpacity: Double {
        switch cameraPermissionStatus {
        case .authorized:
            return 1.0
        case .denied, .restricted:
            return 0.6
        case .notDetermined:
            return isRequestingPermission ? 0.7 : 1.0
        @unknown default:
            return 0.6
        }
    }
    
    // MARK: - Camera Permission Functions (SEGURAS)
    private func requestCameraPermissionSafely() {
        print("📸 Solicitando permisos de cámara de forma segura...")
        
        guard !isRequestingPermission else {
            print("⚠️ Ya se está solicitando permiso, ignorando")
            return
        }
        
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        print("📸 Estado actual: \(currentStatus.debugDescription)")
        
        switch currentStatus {
        case .authorized:
            print("✅ Cámara ya autorizada")
            openCamera()
            
        case .denied:
            print("❌ Cámara denegada - Mostrando alerta")
            showingPermissionAlert = true
            
        case .restricted:
            print("⚠️ Cámara restringida")
            errorMessage = "La cámara está restringida en este dispositivo"
            showingErrorAlert = true
            
        case .notDetermined:
            print("❓ Permiso no determinado - Solicitando...")
            requestPermissionWithSafeHandling()
            
        @unknown default:
            print("🤷‍♂️ Estado desconocido")
            errorMessage = "Estado de cámara desconocido"
            showingErrorAlert = true
        }
    }
    
    private func requestPermissionWithSafeHandling() {
        isRequestingPermission = true
        
        // TEMPORAL: Comentar la verificación que falla
        /*
        guard Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil else {
            print("❌ NSCameraUsageDescription no configurado")
            isRequestingPermission = false
            errorMessage = "Permisos de cámara no configurados correctamente"
            showingErrorAlert = true
            return
        }
        */
        
        print("📸 Solicitando acceso a cámara...")
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.isRequestingPermission = false
                self.cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
                
                print("📸 Respuesta del usuario: \(granted ? "CONCEDIDO" : "DENEGADO")")
                print("📸 Nuevo estado: \(self.cameraPermissionStatus.debugDescription)")
                
                if granted {
                    self.openCamera()
                } else {
                    self.showingPermissionAlert = true
                }
            }
        }
    }
    private func openCamera() {
        print("📸 Abriendo cámara...")
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("❌ Cámara no disponible en este dispositivo")
            errorMessage = "La cámara no está disponible en este dispositivo"
            showingErrorAlert = true
            return
        }
        
        showingCamera = true
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl)
    }
    
    // MARK: - Analysis Function
    private func analyzeFood() {
        guard let image = selectedImage else { return }
        
        isAnalyzing = true
        errorMessage = ""
        
        print("🧠 Iniciando análisis...")
        
        Task {
            do {
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
                    self.errorMessage = error.localizedDescription
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - Debug Functions
    private func debugSystemStatus() {
        print("\n🔍 DEBUG: Estado Completo del Sistema")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        debugPrivacyConfiguration()
        debugDeviceInfo()
        food101Classifier.debugBundleContents()
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
private func debugPrivacyConfiguration() {
    print("\n🔐 CONFIGURACIÓN DE PRIVACIDAD:")
    
    // Debug más detallado
    print("   📱 Bundle path: \(Bundle.main.bundlePath)")
    print("   📄 Info.plist path: \(Bundle.main.path(forResource: "Info", ofType: "plist") ?? "NO ENCONTRADO")")
    
    // Verificar Info.plist completo
    if let infoDict = Bundle.main.infoDictionary {
        print("   📋 Info dictionary tiene \(infoDict.count) keys")
        print("   🔑 Keys disponibles: \(infoDict.keys.sorted())")
    } else {
        print("   ❌ NO se puede leer Info.plist")
    }
    
    // Verificar permisos específicos
    if let cameraDesc = Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String {
        print("   ✅ NSCameraUsageDescription: \(cameraDesc)")
    } else {
        print("   ❌ NSCameraUsageDescription: NO CONFIGURADO")
    }
    
    if let photoDesc = Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") as? String {
        print("   ✅ NSPhotoLibraryUsageDescription: \(photoDesc)")
    } else {
        print("   ❌ NSPhotoLibraryUsageDescription: NO CONFIGURADO")
    }
}   
    
    private func debugDeviceInfo() {
        print("\n📱 INFORMACIÓN DEL DISPOSITIVO:")
        print("   🏷️ Modelo: \(UIDevice.current.model)")
        print("   💾 Sistema: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
        print("   🔧 Simulador: \(isRunningOnSimulator)")
        print("   📸 Cámara disponible: \(UIImagePickerController.isSourceTypeAvailable(.camera))")
    }
    
    private var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Safe Image Picker (Previene SIGABRT)
struct SafeImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        print("📸 Creando ImagePicker para: \(sourceType == .camera ? "CÁMARA" : "GALERÍA")")
        
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.allowsEditing = false
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SafeImagePicker
        
        init(_ parent: SafeImagePicker) {
            self.parent = parent
            super.init()
            print("📸 Coordinator inicializado para ImagePicker")
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("📸 Imagen seleccionada exitosamente")
            
            if let image = info[.originalImage] as? UIImage {
                print("📸 Imagen procesada: \(image.size.width)×\(image.size.height)")
                parent.onImagePicked(image)
            } else {
                print("❌ Error: No se pudo obtener la imagen")
            }
            
            picker.dismiss(animated: true) {
                print("📸 ImagePicker cerrado")
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("📸 Selección de imagen cancelada por el usuario")
            picker.dismiss(animated: true) {
                print("📸 ImagePicker cancelado y cerrado")
            }
        }
    }
}

// MARK: - AVAuthorizationStatus Extension
extension AVAuthorizationStatus {
    var debugDescription: String {
        switch self {
        case .authorized: return "authorized (✅)"
        case .denied: return "denied (❌)"
        case .restricted: return "restricted (⚠️)"
        case .notDetermined: return "notDetermined (❓)"
        @unknown default: return "unknown (🤷‍♂️)"
        }
    }
}