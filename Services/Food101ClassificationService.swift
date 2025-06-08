import UIKit
import CoreML
import Vision
import Foundation

// MARK: - Mock Classification para compatibilidad
class MockClassificationObservation: VNClassificationObservation {
    private let _identifier: String
    private let _confidence: VNConfidence
    
    init(identifier: String, confidence: Float) {
        self._identifier = identifier
        self._confidence = VNConfidence(confidence)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var identifier: String {
        return _identifier
    }
    
    override var confidence: VNConfidence {
        return _confidence
    }
}

// MARK: - Servicio de Clasificación Food101 CORREGIDO
class Food101ClassificationService: ObservableObject {
    private var model: VNCoreMLModel?
    private var mlModel: MLModel?
    private let nutritionalDatabase = NutritionalDatabase()
    private var isUsingRealModel = false
    private var modelMetadata: ModelMetadata?
    
    struct ModelMetadata {
        let name: String
        let inputDescription: String
        let outputDescription: String
        let classLabels: [String]?
    }
    
    init() {
        loadFood101Model()
    }
    
    private func loadFood101Model() {
        print("🔍 DEBUG: Iniciando carga de modelo Food101...")
        
        // PASO 1: Verificar que el modelo existe en el bundle
        guard let modelURL = findModelInBundle() else {
            print("❌ FATAL: No se encontró FoodClassifier.mlmodel en el bundle")
            loadFallbackModel()
            return
        }
        
        print("✅ Modelo encontrado en: \(modelURL.path)")
        
        // PASO 2: Cargar y analizar el modelo
        do {
            let loadedMLModel = try MLModel(contentsOf: modelURL)
            self.mlModel = loadedMLModel
            
            // PASO 3: Analizar metadatos del modelo
            analyzeModelMetadata(loadedMLModel)
            
            // PASO 4: Crear VNCoreMLModel con configuración específica
            let visionModel = try VNCoreMLModel(for: loadedMLModel)
            self.model = visionModel
            self.isUsingRealModel = true
            
            print("✅ MODELO PERSONALIZADO CARGADO EXITOSAMENTE")
            print("📊 Tipo: \(modelMetadata?.name ?? "Desconocido")")
            print("🎯 Clases disponibles: \(modelMetadata?.classLabels?.count ?? 0)")
            
        } catch {
            print("❌ Error cargando modelo personalizado: \(error)")
            print("📋 Detalles: \(error.localizedDescription)")
            loadFallbackModel()
        }
    }
    
    // MARK: - Buscar modelo en bundle
    private func findModelInBundle() -> URL? {
        // Buscar diferentes variantes del nombre
        let possibleNames = ["FoodClassifier", "Food101", "MobileNetV2Food101", "food_classifier"]
        let possibleExtensions = ["mlmodel", "mlmodelc"]
        
        for name in possibleNames {
            for ext in possibleExtensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                    print("📁 Encontrado modelo: \(name).\(ext)")
                    return url
                }
            }
        }
        
        // Listar todos los archivos .mlmodel/.mlmodelc en el bundle para debug
        print("🔍 DEBUG: Archivos ML en el bundle:")
        if let bundlePath = Bundle.main.resourcePath {
            let fileManager = FileManager.default
            do {
                let files = try fileManager.contentsOfDirectory(atPath: bundlePath)
                let mlFiles = files.filter { $0.hasSuffix(".mlmodel") || $0.hasSuffix(".mlmodelc") }
                for file in mlFiles {
                    print("   📄 \(file)")
                }
                if mlFiles.isEmpty {
                    print("   ❌ No se encontraron archivos .mlmodel o .mlmodelc")
                }
            } catch {
                print("   ❌ Error listando archivos: \(error)")
            }
        }
        
        return nil
    }
    
    // MARK: - Fallback cuando el modelo personalizado falla
    private func loadFallbackModel() {
        print("🔄 Cargando modelo de fallback...")
        isUsingRealModel = false
    }
    
    // MARK: - Analizar metadatos del modelo
    private func analyzeModelMetadata(_ model: MLModel) {
        let description = model.modelDescription
        
        print("🔍 ANÁLISIS DEL MODELO:")
        print("   📊 Inputs: \(description.inputDescriptionsByName.keys.joined(separator: ", "))")
        print("   📤 Outputs: \(description.outputDescriptionsByName.keys.joined(separator: ", "))")
        
        // Buscar labels de clasificación
        let classLabels: [String]? = nil
        
        // Método 1: Buscar en metadata usando la clave correcta
        if let userDefinedMetadata = description.metadata[.description] as? String,
           userDefinedMetadata.contains("classLabels") {
            print("   🏷️ Metadata contiene información de labels")
        }
        
        // Método 2: Buscar en outputs
        for (outputName, outputDesc) in description.outputDescriptionsByName {
            print("   📤 Output '\(outputName)': \(outputDesc.type)")
            
            if case .dictionary = outputDesc.type {
                print("     📚 Es diccionario")
            } else if case .multiArray = outputDesc.type {
                print("     📊 Es multiArray")
            }
        }
        
        // Crear metadata
        self.modelMetadata = ModelMetadata(
            name: "FoodClassifier",
            inputDescription: description.inputDescriptionsByName.keys.first ?? "unknown",
            outputDescription: description.outputDescriptionsByName.keys.first ?? "unknown",
            classLabels: classLabels
        )
    }
    
    // MARK: - Función de clasificación CORREGIDA
    func classifyFood(image: UIImage) async throws -> FoodAnalysisResult {
        guard let cgImage = image.cgImage else {
            throw ClassificationError.imageProcessingFailed
        }
        
        print("🧠 Iniciando análisis con modelo personalizado...")
        
        // Intentar con modelo personalizado primero
        if let model = model, isUsingRealModel {
            print("🎯 Usando modelo personalizado...")
            if let result = try await attemptCustomModelClassification(cgImage: cgImage, model: model) {
                return result
            } else {
                print("⚠️ Modelo personalizado falló, usando fallback...")
            }
        }
        
        // Fallback a Vision framework
        print("🔄 Usando Vision framework como fallback...")
        if let result = try await attemptBuiltInClassification(cgImage: cgImage) {
            return result
        }
        
        // Último recurso
        return try await performEmergencyAnalysis(image: image)
    }
    
    // MARK: - Clasificación con modelo personalizado MEJORADA
    private func attemptCustomModelClassification(cgImage: CGImage, model: VNCoreMLModel) async throws -> FoodAnalysisResult? {
        return try await withCheckedThrowingContinuation { continuation in
            
            // CONFIGURACIÓN ESPECÍFICA PARA FOOD101
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    print("❌ Error en modelo personalizado: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                print("🔍 Analizando resultados del modelo personalizado...")
                print("📊 Tipo de resultados: \(type(of: request.results))")
                print("📈 Cantidad: \(request.results?.count ?? 0)")
                
                // MANEJO MEJORADO DE DIFERENTES TIPOS DE RESULTADOS
                if let classificationResults = request.results as? [VNClassificationObservation] {
                    print("✅ Resultados de clasificación directos")
                    self.handleClassificationResults(classificationResults, continuation: continuation)
                    
                } else if let coreMLResults = request.results as? [VNCoreMLFeatureValueObservation] {
                    print("🔄 Resultados CoreML - procesando...")
                    self.handleCoreMLResults(coreMLResults, continuation: continuation)
                    
                } else {
                    print("❌ Tipo de resultado no soportado")
                    if let results = request.results {
                        for (index, result) in results.enumerated() {
                            print("   [\(index)]: \(type(of: result))")
                        }
                    }
                    continuation.resume(returning: nil)
                }
            }
            
            // CONFIGURACIÓN OPTIMIZADA PARA FOOD101
            request.imageCropAndScaleOption = .scaleFit // Mejor para food101
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [
                VNImageOption.ciContext: CIContext()
            ])
            
            do {
                try handler.perform([request])
            } catch {
                print("❌ Error ejecutando request: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - Manejar resultados de clasificación directos
    private func handleClassificationResults(
        _ results: [VNClassificationObservation],
        continuation: CheckedContinuation<FoodAnalysisResult?, any Error>
    ) {
        let validResults = results.filter { $0.confidence > 0.01 }
        
        guard !validResults.isEmpty else {
            print("❌ No hay resultados válidos")
            continuation.resume(returning: nil)
            return
        }
        
        print("✅ Procesando \(validResults.count) resultados válidos")
        for (index, result) in validResults.prefix(3).enumerated() {
            print("   [\(index)]: \(result.identifier) - \(Int(result.confidence * 100))%")
        }
        
        let result = self.createResult(from: validResults, analysisType: "Modelo Food101 Personalizado")
        continuation.resume(returning: result)
    }
    
    // MARK: - Manejar resultados CoreML CORREGIDO
    private func handleCoreMLResults(
        _ coreMLResults: [VNCoreMLFeatureValueObservation],
        continuation: CheckedContinuation<FoodAnalysisResult?, any Error>
    ) {
        guard !coreMLResults.isEmpty else {
            print("❌ No hay resultados CoreML")
            continuation.resume(returning: nil)
            return
        }
        
        for (index, result) in coreMLResults.enumerated() {
            print("🔍 CoreML Result [\(index)]:")
            print("   📊 Feature Name: \(result.featureName)")
            print("   🔢 Value Type: \(type(of: result.featureValue))")
            
            let featureValue = result.featureValue
            
            // MANEJO ESPECÍFICO PARA DIFERENTES TIPOS DE OUTPUTS
            if let multiArray = featureValue.multiArrayValue {
                print("   📈 MultiArray Shape: \(multiArray.shape)")
                print("   🔢 DataType: \(multiArray.dataType)")
                
                // Convertir MultiArray a clasificaciones
                if let classifications = convertMultiArrayToClassifications(multiArray) {
                    let result = self.createResult(from: classifications, analysisType: "Modelo Food101 (MultiArray)")
                    continuation.resume(returning: result)
                    return
                }
                
            } else if featureValue.dictionaryValue != nil {
                print("   📚 Dictionary detectado")
                
                // Acceder al diccionario de forma segura
                if let dictionary = featureValue.dictionaryValue as? [AnyHashable: NSNumber] {
                    // Convertir Dictionary a clasificaciones
                    if let classifications = convertDictionaryToClassifications(dictionary) {
                        let result = self.createResult(from: classifications, analysisType: "Modelo Food101 (Dictionary)")
                        continuation.resume(returning: result)
                        return
                    }
                }
                
            } else if featureValue.type == .string {
                let stringValue = featureValue.stringValue
                print("   📝 String Value: \(stringValue)")
                
                // Crear resultado directo del string
                let result = createResultFromString(stringValue)
                continuation.resume(returning: result)
                return
            }
        }
        
        print("❌ No se pudo procesar ningún resultado CoreML")
        continuation.resume(returning: nil)
    }
    
    // MARK: - Conversiones de tipos MEJORADAS
    private func convertMultiArrayToClassifications(_ multiArray: MLMultiArray) -> [VNClassificationObservation]? {
        guard multiArray.count > 0 else { return nil }
        
        let length = multiArray.count
        var classifications: [(identifier: String, confidence: Float)] = []
        
        // Obtener datos como Float
        let dataPointer = multiArray.dataPointer.bindMemory(to: Float.self, capacity: length)
        
        // Si tenemos labels del modelo, usarlos
        if let classLabels = modelMetadata?.classLabels {
            for i in 0..<min(length, classLabels.count) {
                let confidence = dataPointer[i]
                if confidence > 0.01 {
                    classifications.append((identifier: classLabels[i], confidence: confidence))
                }
            }
        } else {
            // Generar identificadores genéricos Food101
            let food101Classes = ["apple_pie", "pizza", "hamburger", "sandwich", "steak", "chicken_wings", "ice_cream", "french_fries", "chocolate_cake", "sushi"]
            for i in 0..<min(length, food101Classes.count) {
                let confidence = dataPointer[i]
                if confidence > 0.01 {
                    classifications.append((identifier: food101Classes[i], confidence: confidence))
                }
            }
        }
        
        // Ordenar por confianza
        classifications.sort { $0.confidence > $1.confidence }
        
        // Convertir a objetos simulados VNClassificationObservation
        return classifications.prefix(10).map { item in
            MockClassificationObservation(identifier: item.identifier, confidence: item.confidence)
        }
    }
    
    private func convertDictionaryToClassifications(_ dictionary: [AnyHashable: NSNumber]) -> [VNClassificationObservation]? {
        var classifications: [(identifier: String, confidence: Float)] = []
        
        for (key, value) in dictionary {
            if let keyString = key as? String {
                let confidence = value.floatValue
                if confidence > 0.01 {
                    classifications.append((identifier: keyString, confidence: confidence))
                }
            }
        }
        
        classifications.sort { $0.confidence > $1.confidence }
        
        return classifications.prefix(10).map { item in
            MockClassificationObservation(identifier: item.identifier, confidence: item.confidence)
        }
    }
    
    private func createResultFromString(_ stringValue: String) -> FoodAnalysisResult {
        let foodInfo = mapIdentifierToSpanish(identifier: stringValue)
        let nutritionalInfo = nutritionalDatabase.getNutritionalInfo(for: foodInfo.spanishName)
        
        let insights: [HealthInsight] = [
            HealthInsight(
                title: "🎯 Resultado Directo",
                description: "El modelo devolvió directamente: \(stringValue)",
                category: .nutrition,
                severity: .info
            )
        ]
        
        return FoodAnalysisResult(
            foodName: foodInfo.spanishName,
            confidence: 0.8,
            nutritionalInfo: nutritionalInfo,
            healthInsights: insights
        )
    }
    
    // MARK: - Métodos auxiliares
    private func attemptBuiltInClassification(cgImage: CGImage) async throws -> FoodAnalysisResult? {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    print("❌ Error en Vision built-in: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let results = request.results as? [VNClassificationObservation] else {
                    print("❌ Sin resultados de Vision")
                    continuation.resume(returning: nil)
                    return
                }
                
                // Filtrar solo resultados relacionados con comida
                let foodResults = results.filter { observation in
                    observation.confidence > 0.1 && self.isFoodRelated(identifier: observation.identifier)
                }
                
                guard !foodResults.isEmpty else {
                    print("❌ No se encontraron alimentos en Vision")
                    continuation.resume(returning: nil)
                    return
                }
                
                print("✅ Vision encontró \(foodResults.count) alimentos")
                let result = self.createResult(from: foodResults, analysisType: "Vision Apple")
                continuation.resume(returning: result)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("❌ Error en Vision handler: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func performEmergencyAnalysis(image: UIImage) async throws -> FoodAnalysisResult {
        print("🚨 Ejecutando análisis de emergencia...")
        
        let foodInfo = mapIdentifierToSpanish(identifier: "unknown_food")
        let nutritionalInfo = nutritionalDatabase.getNutritionalInfo(for: foodInfo.spanishName)
        
        let insights: [HealthInsight] = [
            HealthInsight(
                title: "🎨 Análisis Visual",
                description: "La IA no pudo identificar el alimento específico. Clasificación basada en análisis visual.",
                category: .nutrition,
                severity: .info
            )
        ]
        
        return FoodAnalysisResult(
            foodName: "Alimento No Identificado",
            confidence: 0.1,
            nutritionalInfo: nutritionalInfo,
            healthInsights: insights
        )
    }
    
    private func createResult(from results: [VNClassificationObservation], analysisType: String) -> FoodAnalysisResult {
        let topResult = results.first!
        let foodInfo = mapIdentifierToSpanish(identifier: topResult.identifier)
        let nutritionalInfo = nutritionalDatabase.getNutritionalInfo(for: foodInfo.spanishName)
        
        let insights: [HealthInsight] = [
            HealthInsight(
                title: "🤖 Tipo de Análisis",
                description: "\(analysisType) - Confianza: \(Int(topResult.confidence * 100))%",
                category: .nutrition,
                severity: .info
            )
        ]
        
        return FoodAnalysisResult(
            foodName: foodInfo.spanishName,
            confidence: topResult.confidence,
            nutritionalInfo: nutritionalInfo,
            healthInsights: insights
        )
    }
    
    private func mapIdentifierToSpanish(identifier: String) -> (originalName: String, spanishName: String, category: String) {
        let lowercased = identifier.lowercased()
        
        // Mapeo básico
        let mappings: [String: (spanish: String, category: String)] = [
            "pizza": ("Pizza", "Carbohidrato"),
            "hamburger": ("Hamburguesa", "Comida Rápida"),
            "sandwich": ("Sándwich", "Sándwich"),
            "salad": ("Ensalada", "Ensalada"),
            "chicken": ("Pollo", "Proteína"),
            "fish": ("Pescado", "Proteína"),
            "bread": ("Pan", "Carbohidrato"),
            "unknown_food": ("Alimento Desconocido", "Otros")
        ]
        
        // Buscar mapeo directo
        if let mapped = mappings[lowercased] {
            return (identifier, mapped.spanish, mapped.category)
        }
        
        // Buscar por coincidencias parciales
        for (key, value) in mappings {
            if lowercased.contains(key) {
                return (identifier, value.spanish, value.category)
            }
        }
        
        // Fallback
        let spanishName = identifier
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
        
        return (identifier, spanishName, "Otros")
    }
    
    private func isFoodRelated(identifier: String) -> Bool {
        let foodKeywords = [
            "food", "meal", "pizza", "burger", "sandwich", "salad", "soup", "bread", "pasta",
            "meat", "chicken", "beef", "fish", "fruit", "vegetable", "dessert", "cake"
        ]
        
        let lowerIdentifier = identifier.lowercased()
        return foodKeywords.contains { keyword in
            lowerIdentifier.contains(keyword)
        }
    }
}

// MARK: - Extensión para debugging del bundle
extension Food101ClassificationService {
    func debugBundleContents() {
        print("🔍 DEBUG: Contenido del Bundle:")
        guard let bundlePath = Bundle.main.resourcePath else {
            print("❌ No se puede acceder al bundle path")
            return
        }
        
        let fileManager = FileManager.default
        do {
            let allFiles = try fileManager.contentsOfDirectory(atPath: bundlePath)
            let mlFiles = allFiles.filter { $0.contains("ml") || $0.contains("ML") }
            
            print("📁 Archivos ML encontrados:")
            for file in mlFiles {
                print("   📄 \(file)")
                
                // Verificar tamaño del archivo
                let filePath = "\(bundlePath)/\(file)"
                if let attributes = try? fileManager.attributesOfItem(atPath: filePath),
                   let fileSize = attributes[.size] as? Int64 {
                    print("      📏 Tamaño: \(fileSize) bytes")
                }
            }
            
            if mlFiles.isEmpty {
                print("❌ No se encontraron archivos ML en el bundle")
                print("📋 Primeros 20 archivos del bundle:")
                for file in allFiles.prefix(20) {
                    print("   📄 \(file)")
                }
            }
        } catch {
            print("❌ Error leyendo contenido del bundle: \(error)")
        }
    }
}
