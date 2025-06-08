import SwiftUI

struct UserSetupView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userProfiles: UserProfiles
    
    @State private var name = ""
    @State private var age = ""
    @State private var selectedDiabetesType: DiabetesType = .type1
    @State private var hasInsurance = false
    @State private var preferredLanguage: Language = .spanish
    @State private var currentStep = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress Indicator
                ProgressView("Paso \(currentStep + 1) de 3", value: Double(currentStep + 1), total: 3)
                    .padding()
                
                TabView(selection: $currentStep) {
                    // Step 1: Personal Info
                    PersonalInfoStep(name: $name, age: $age)
                        .tag(0)
                    
                    // Step 2: Medical Info
                    MedicalInfoStep(selectedDiabetesType: $selectedDiabetesType, hasInsurance: $hasInsurance)
                        .tag(1)
                    
                    // Step 3: Preferences
                    PreferencesStep(preferredLanguage: $preferredLanguage)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation Buttons
                HStack {
                    if currentStep > 0 {
                        Button("Anterior") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    if currentStep < 2 {
                        Button("Siguiente") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .disabled(!canContinue)
                        .foregroundColor(canContinue ? .blue : .gray)
                    } else {
                        Button("Finalizar") {
                            saveUserProfile()
                            withAnimation(.spring()) {
                                appState.navigateToMain()
                            }
                        }
                        .disabled(!canFinish)
                        .foregroundColor(canFinish ? .white : .gray)
                        .padding()
                        .background(canFinish ? Color.blue : Color.gray.opacity(0.3))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    var canContinue: Bool {
        switch currentStep {
        case 0: return !name.isEmpty && !age.isEmpty
        case 1: return true
        default: return true
        }
    }
    
    var canFinish: Bool {
        !name.isEmpty && !age.isEmpty
    }
    
    func saveUserProfile() {
        let profile = UserProfile(
            name: name,
            age: Int(age) ?? 0,
            diabetesType: selectedDiabetesType.rawValue,
            hasInsurance: hasInsurance,
            preferredLanguage: preferredLanguage.rawValue
        )
        userProfiles.updateProfile(profile)
    }
}

// MARK: - Setup Steps
struct PersonalInfoStep: View {
    @Binding var name: String
    @Binding var age: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Información Personal")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                TextField("Nombre completo", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Edad", text: $age)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct MedicalInfoStep: View {
    @Binding var selectedDiabetesType: DiabetesType
    @Binding var hasInsurance: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Información Médica")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                VStack(alignment: .leading) {
                    Text("Tipo de Diabetes")
                        .font(.headline)
                    
                    Picker("Tipo de Diabetes", selection: $selectedDiabetesType) {
                        ForEach(DiabetesType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Toggle("¿Tienes seguro médico?", isOn: $hasInsurance)
                    .toggleStyle(SwitchToggleStyle())
            }
            
            Spacer()
        }
        .padding()
    }
}

struct PreferencesStep: View {
    @Binding var preferredLanguage: Language
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Preferencias")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                VStack(alignment: .leading) {
                    Text("Idioma preferido")
                        .font(.headline)
                    
                    Picker("Idioma", selection: $preferredLanguage) {
                        ForEach(Language.allCases) { language in
                            Text(language.rawValue).tag(language)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Supporting Enums
enum DiabetesType: String, CaseIterable, Identifiable {
    case type1 = "Tipo 1"
    case type2 = "Tipo 2"
    case gestational = "Gestacional"
    
    var id: String { rawValue }
}

enum Language: String, CaseIterable, Identifiable {
    case spanish = "Español"
    case english = "English"
    
    var id: String { rawValue }
}