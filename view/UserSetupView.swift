import SwiftUI

struct UserSetupView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userProfiles: UserProfiles
    
    @State private var currentStep = 1
    @State private var name = ""
    @State private var age = ""
    @State private var selectedDiabetesType: DiabetesType = .type2
    @State private var diagnosisYear = ""
    @State private var enableNotifications = true
    @State private var selectedUnits = "mg/dL"
    
    // NUEVO: Estados para manejar focus del teclado
    @FocusState private var ageFieldFocused: Bool
    @FocusState private var yearFieldFocused: Bool
    
    private let totalSteps = 3
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header - Título principal
                VStack(spacing: 20) {
                    Text("Configuración")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .padding(.top, 60)
                    
                    // Indicador de progreso
                    VStack(spacing: 12) {
                        Text("Paso \(currentStep) de \(totalSteps)")
                            .font(.title3)
                            .fontWeight(.regular)
                            .foregroundColor(.black)
                        
                        HStack(spacing: 4) {
                            ForEach(1...totalSteps, id: \.self) { step in
                                Rectangle()
                                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(height: 4)
                                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                            }
                        }
                        .padding(.horizontal, 60)
                    }
                }
                .padding(.bottom, 80)
                
                // Contenido del paso actual
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Botón de navegación
                navigationButton
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        // NUEVO: Toolbar para campos numéricos
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") {
                    hideKeyboard()
                }
                .foregroundColor(.blue)
                .fontWeight(.semibold)
            }
        }
        // NUEVO: Gesture para cerrar teclado tocando fuera
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 1:
            personalInfoStep
        case 2:
            medicalInfoStep
        case 3:
            preferencesStep
        default:
            EmptyView()
        }
    }
    
    // MARK: - Paso 1: Información Personal (MEJORADO)
    private var personalInfoStep: some View {
        VStack(spacing: 0) {
            // Ícono circular azul
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 40)
            
            // Título
            Text("Información Personal")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .padding(.bottom, 60)
            
            // Campos de entrada MEJORADOS
            VStack(spacing: 40) {
                // Campo Nombre
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Nombre Completo", text: $name)
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                        .padding(.vertical, 16)
                        .background(Color.clear)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.gray.opacity(0.4)),
                            alignment: .bottom
                        )
                }
                
                // Campo Edad MEJORADO
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Edad", text: $age)
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                        .keyboardType(.numberPad)
                        .focused($ageFieldFocused)
                        .padding(.vertical, 16)
                        .background(Color.clear)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(ageFieldFocused ? Color.blue : Color.gray.opacity(0.4)),
                            alignment: .bottom
                        )
                        .onChange(of: age) { newValue in
                            // Filtrar solo números y limitar a 3 dígitos
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered.count <= 3 {
                                age = filtered
                            } else {
                                age = String(filtered.prefix(3))
                            }
                        }
                    
                    // Helper text
                    if ageFieldFocused {
                        Text("Toca 'Listo' cuando termines")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .transition(.opacity)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Paso 2: Información Médica (MEJORADO)
    private var medicalInfoStep: some View {
        VStack(spacing: 0) {
            // Ícono médico
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.9))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 40)
            
            // Título
            Text("Información Médica")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .padding(.bottom, 40)
            
            // Campos médicos MEJORADOS
            VStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Tipo de Diabetes")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Picker("Tipo", selection: $selectedDiabetesType) {
                        ForEach(DiabetesType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Año de Diagnóstico")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    TextField("2020", text: $diagnosisYear)
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                        .keyboardType(.numberPad)
                        .focused($yearFieldFocused)
                        .padding(.vertical, 16)
                        .background(Color.clear)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(yearFieldFocused ? Color.blue : Color.gray.opacity(0.4)),
                            alignment: .bottom
                        )
                        .onChange(of: diagnosisYear) { newValue in
                            // Filtrar solo números y limitar a 4 dígitos (año)
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered.count <= 4 {
                                diagnosisYear = filtered
                            } else {
                                diagnosisYear = String(filtered.prefix(4))
                            }
                        }
                    
                    // Helper text para año
                    if yearFieldFocused {
                        Text("Ejemplo: 2020 • Toca 'Listo' cuando termines")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .transition(.opacity)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Paso 3: Preferencias (Sin cambios)
    private var preferencesStep: some View {
        VStack(spacing: 0) {
            // Ícono de configuración
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 40)
            
            // Título
            Text("Configuración Final")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .padding(.bottom, 40)
            
            // Opciones de configuración
            VStack(spacing: 25) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Unidades de Glucosa")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Picker("Unidades", selection: $selectedUnits) {
                        Text("mg/dL").tag("mg/dL")
                        Text("mmol/L").tag("mmol/L")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Toggle("Activar Notificaciones", isOn: $enableNotifications)
                    .font(.headline)
                    .foregroundColor(.black)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Botón de navegación
    @ViewBuilder
    private var navigationButton: some View {
        HStack {
            Spacer()
            
            Button(action: {
                hideKeyboard() // Cerrar teclado antes de navegar
                
                if currentStep < totalSteps {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                } else {
                    // Finalizar setup
                    saveUserProfile()
                    withAnimation(.spring()) {
                        appState.navigateToMain()
                    }
                }
            }) {
                Text(currentStep < totalSteps ? "Siguiente" : "Finalizar")
                    .font(.system(size: 18))
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .disabled(!canContinue)
            .opacity(canContinue ? 1.0 : 0.5)
        }
    }
    
    // MARK: - Validaciones MEJORADAS
    private var canContinue: Bool {
        switch currentStep {
        case 1:
            let nameValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let ageValid = !age.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                          (Int(age) ?? 0) > 0 && (Int(age) ?? 0) < 150
            return nameValid && ageValid
        case 2:
            let yearValid = !diagnosisYear.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                           diagnosisYear.count == 4 && 
                           (Int(diagnosisYear) ?? 0) >= 1950 && 
                           (Int(diagnosisYear) ?? 0) <= Calendar.current.component(.year, from: Date())
            return yearValid
        case 3:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Helper Functions
    private func hideKeyboard() {
        ageFieldFocused = false
        yearFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Guardar perfil
    private func saveUserProfile() {
        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            age: Int(age) ?? 0,
            diabetesType: selectedDiabetesType.rawValue,
            diagnosisYear: diagnosisYear.trimmingCharacters(in: .whitespacesAndNewlines),
            hasInsurance: false,
            preferredLanguage: "Español",
            preferredUnits: selectedUnits,
            notificationsEnabled: enableNotifications
        )
        userProfiles.updateProfile(profile)
    }
}