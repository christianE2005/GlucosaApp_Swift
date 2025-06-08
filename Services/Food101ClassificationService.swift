import UIKit
import CoreML
import Vision
import Foundation

// MARK: - Servicio de Clasificación Food101 CORREGIDO
class Food101ClassificationService: ObservableObject {
    private var model: VNCoreMLModel?
    private var mlModel: MLModel?
    private let nutritionalDatabase = NutritionalDatabase()
    private var isUsingRealModel = false
    private var modelMetadata: ModelMetadata?
    
    // MARK: - Configuración específica para Food101
    private struct Food101Config {
        static let expectedInputSize = CGSize(width: 224, height: 224) // Típico para MobileNet
        static let meanValues: [Float] = [0.485, 0.456, 0.406] // ImageNet normalization
        static let stdValues: [Float] = [0.229, 0.224, 0.225]
        static let minimumConfidence: Float = 0.05
    }
    
    struct ModelMetadata {
        let name: String
        let inputDescription: String
        let outputDescription: String
        let classLabels: [String]?
        let inputShape: [Int]?
        let requiresNormalization: Bool
    }
    
    init() {
        loadFood101Model()
    }
    
    // MARK: - Carga del modelo MEJORADA
    private func loadFood101Model() {
        print("🔍 DEBUG: Iniciando carga de modelo Food101...")
        
        guard let modelURL = findModelInBundle() else {
            print("❌ FATAL: No se encontró FoodClassifier.mlmodel en el bundle")
            loadFallbackModel()
            return
        }
        
        print("✅ Modelo encontrado en: \(modelURL.path)")
        
        do {
            // CONFIGURACIÓN ESPECÍFICA PARA COREML
            let config = MLModelConfiguration()
            config.computeUnits = .all // Usar GPU si está disponible
            
            let loadedMLModel = try MLModel(contentsOf: modelURL, configuration: config)
            self.mlModel = loadedMLModel
            
            // Analizar metadatos ANTES de crear VNCoreMLModel
            analyzeModelMetadata(loadedMLModel)
            
            // Crear VNCoreMLModel con configuración optimizada
            let visionModel = try VNCoreMLModel(for: loadedMLModel)
            self.model = visionModel
            self.isUsingRealModel = true
            
            print("✅ MODELO PERSONALIZADO CARGADO EXITOSAMENTE")
            print("📊 Input Shape: \(modelMetadata?.inputShape ?? [])")
            print("🎯 Clases: \(modelMetadata?.classLabels?.count ?? 0)")
            
        } catch {
            print("❌ Error cargando modelo: \(error)")
            if let mlError = error as? MLModelError {
                print("📋 MLModelError: \(mlError.localizedDescription)")
            }
            loadFallbackModel()
        }
    }
    
    // MARK: - Análisis de metadatos MEJORADO
    private func analyzeModelMetadata(_ model: MLModel) {
        let description = model.modelDescription
        
        print("🔍 ANÁLISIS DETALLADO DEL MODELO:")
        
        // Analizar inputs
        var inputShape: [Int]? = nil
        var requiresNormalization = true
        
        for (inputName, inputDesc) in description.inputDescriptionsByName {
            print("   📥 Input '\(inputName)':")
            print("      🔧 Tipo: \(inputDesc.type)")
            
            switch inputDesc.type {
            case .image:
                print("      🖼️ Es imagen:")
                // Para imágenes, obtener constraints del imageConstraint
                if let imageConstraint = inputDesc.imageConstraint {
                    print("         📏 Tamaño: \(imageConstraint.pixelsWide) x \(imageConstraint.pixelsHigh)")
                    print("         🎨 Formato: \(imageConstraint.pixelFormatType)")
                    inputShape = [Int(imageConstraint.pixelsHigh), Int(imageConstraint.pixelsWide), 3]
                } else {
                    print("         ⚠️ No hay imageConstraint disponible")
                    // Usar tamaño por defecto para Food101
                    inputShape = [224, 224, 3]
                }
                
            case .multiArray:
                print("      📊 Es MultiArray:")
                if let arrayConstraint = inputDesc.multiArrayConstraint {
                    print("         📐 Shape: \(arrayConstraint.shape)")
                    print("         🔢 DataType: \(arrayConstraint.dataType)")
                    inputShape = arrayConstraint.shape.map { $0.intValue }
                } else {
                    print("         ⚠️ No hay multiArrayConstraint disponible")
                }
                
            case .dictionary:
                print("      📚 Es Dictionary")
                
            case .sequence:
                print("      🔄 Es Sequence")
                
            case .int64:
                print("      🔢 Es Int64")
                
            case .double:
                print("      🔢 Es Double")
                
            case .string:
                print("      📝 Es String")
                
            @unknown default:
                print("      ❓ Tipo desconocido: \(inputDesc.type)")
            }
        }
        
        // Analizar outputs y buscar class labels
        var classLabels: [String]? = nil
        
        for (outputName, outputDesc) in description.outputDescriptionsByName {
            print("   📤 Output '\(outputName)': \(outputDesc.type)")
            
            switch outputDesc.type {
            case .dictionary:
                print("      📚 Es Dictionary")
                // Para modelos de clasificación, aquí estarían los labels
                if let dictionaryConstraint = outputDesc.dictionaryConstraint {
                    print("         🔑 Key type: \(dictionaryConstraint.keyType)")
                }
                
            case .multiArray:
                print("      📊 Es MultiArray")
                if let arrayConstraint = outputDesc.multiArrayConstraint {
                    print("         📐 Shape: \(arrayConstraint.shape)")
                    print("         🔢 DataType: \(arrayConstraint.dataType)")
                }
                
            case .string:
                print("      📝 Es String")
                
            default:
                print("      ❓ Otro tipo: \(outputDesc.type)")
            }
        }
        
        // Buscar class labels en metadata
        if let userMetadata = description.metadata[.description] as? String {
            print("   📋 Metadata description: \(userMetadata.prefix(100))...")
        }
        
        // Buscar en author o short description
        if let author = description.metadata[.author] as? String {
            print("   👤 Author: \(author)")
        }
        
        // Intentar obtener class labels del modelo Food101 estándar
        classLabels = getFood101ClassLabels()
        
        self.modelMetadata = ModelMetadata(
            name: "FoodClassifier",
            inputDescription: description.inputDescriptionsByName.keys.first ?? "unknown",
            outputDescription: description.outputDescriptionsByName.keys.first ?? "unknown",
            classLabels: classLabels,
            inputShape: inputShape,
            requiresNormalization: requiresNormalization
        )
    }
    
    // MARK: - Preprocessamiento de imagen CRÍTICO
    private func preprocessImage(_ image: UIImage) -> UIImage? {
        guard let inputShape = modelMetadata?.inputShape,
              inputShape.count >= 2 else {
            print("⚠️ No se puede determinar el tamaño de entrada requerido")
            return image
        }
        
        let targetSize = CGSize(width: inputShape[1], height: inputShape[0])
        print("🎯 Redimensionando imagen a: \(targetSize)")
        
        // Crear contexto de imagen con configuración específica
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        // Dibujar imagen manteniendo aspect ratio y centrando
        let aspectWidth = targetSize.width / image.size.width
        let aspectHeight = targetSize.height / image.size.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        
        let scaledSize = CGSize(
            width: image.size.width * aspectRatio,
            height: image.size.height * aspectRatio
        )
        
        let originX = (targetSize.width - scaledSize.width) / 2
        let originY = (targetSize.height - scaledSize.height) / 2
        let rect = CGRect(x: originX, y: originY, width: scaledSize.width, height: scaledSize.height)
        
        image.draw(in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - Función de clasificación CORREGIDA
    func classifyFood(image: UIImage) async throws -> FoodAnalysisResult {
        print("🧠 Iniciando análisis con modelo personalizado...")
        
        // STEP 1: Preprocessar imagen
        guard let preprocessedImage = preprocessImage(image),
              let cgImage = preprocessedImage.cgImage else {
            throw ClassificationError.imageProcessingFailed
        }
        
        print("✅ Imagen preprocessada correctamente")
        
        // STEP 2: Intentar con modelo personalizado
        if let model = model, isUsingRealModel {
            print("🎯 Usando modelo personalizado...")
            if let result = try await attemptCustomModelClassification(cgImage: cgImage, model: model) {
                return result
            } else {
                print("⚠️ Modelo personalizado falló, usando fallback...")
            }
        }
        
        // STEP 3: Fallback
        return try await performFallbackAnalysis(cgImage: cgImage)
    }
    
    // MARK: - Clasificación con modelo personalizado OPTIMIZADA
    private func attemptCustomModelClassification(cgImage: CGImage, model: VNCoreMLModel) async throws -> FoodAnalysisResult? {
        return try await withCheckedThrowingContinuation { continuation in
            
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    print("❌ Error en modelo personalizado: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                self.processModelResults(request: request, continuation: continuation)
            }
            
            // CONFIGURACIÓN CRÍTICA PARA FOOD101
            request.imageCropAndScaleOption = .centerCrop // ¡CRÍTICO!
            
            // Configuración de imagen optimizada
            let options: [VNImageOption: Any] = [
                .ciContext: CIContext(options: [.workingColorSpace: NSNull()]),
                .properties: [:]
            ]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: options)
            
            do {
                try handler.perform([request])
            } catch {
                print("❌ Error ejecutando request: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - Procesamiento de resultados UNIFICADO
    private func processModelResults(
        request: VNRequest,
        continuation: CheckedContinuation<FoodAnalysisResult?, any Error>
    ) {
        print("🔍 Procesando resultados del modelo...")
        print("📊 Tipo: \(type(of: request.results))")
        print("📈 Cantidad: \(request.results?.count ?? 0)")
        
        // Manejar diferentes tipos de resultados
        if let classificationResults = request.results as? [VNClassificationObservation] {
            print("✅ Resultados de clasificación directos")
            handleDirectClassificationResults(classificationResults, continuation: continuation)
            
        } else if let coreMLResults = request.results as? [VNCoreMLFeatureValueObservation] {
            print("🔄 Resultados CoreML - procesando...")
            handleCoreMLFeatureResults(coreMLResults, continuation: continuation)
            
        } else {
            print("❌ Tipo de resultado no reconocido")
            continuation.resume(returning: nil)
        }
    }
    
    // MARK: - Manejo de resultados de clasificación directos
    private func handleDirectClassificationResults(
        _ results: [VNClassificationObservation],
        continuation: CheckedContinuation<FoodAnalysisResult?, any Error>
    ) {
        let validResults = results.filter { $0.confidence > Food101Config.minimumConfidence }
        
        guard !validResults.isEmpty else {
            print("❌ No hay resultados válidos (umbral: \(Food101Config.minimumConfidence))")
            continuation.resume(returning: nil)
            return
        }
        
        print("✅ Procesando \(validResults.count) resultados válidos:")
        for (index, result) in validResults.prefix(5).enumerated() {
            print("   [\(index + 1)]: \(result.identifier) - \(String(format: "%.1f", result.confidence * 100))%")
        }
        
        let result = createFinalResult(from: validResults, analysisType: "Modelo Food101 Personalizado")
        continuation.resume(returning: result)
    }
    
    // MARK: - Conversión mejorada de MultiArray
    private func convertMultiArrayToClassifications(_ multiArray: MLMultiArray) -> [VNClassificationObservation]? {
        guard let classLabels = modelMetadata?.classLabels else {
            print("❌ No hay class labels disponibles")
            return nil
        }
        
        let count = multiArray.count
        guard count > 0 else { return nil }
        
        print("🔢 Procesando MultiArray: \(count) elementos")
        
        var classifications: [(identifier: String, confidence: Float)] = []
        
        // Acceder a los datos de forma segura
        let dataPointer = multiArray.dataPointer.bindMemory(to: Float.self, capacity: count)
        
        for i in 0..<min(count, classLabels.count) {
            let confidence = dataPointer[i]
            if confidence > Food101Config.minimumConfidence {
                classifications.append((identifier: classLabels[i], confidence: confidence))
            }
        }
        
        // Ordenar por confianza
        classifications.sort { $0.confidence > $1.confidence }
        
        print("✅ Convertidas \(classifications.count) clasificaciones válidas")
        
        return classifications.prefix(10).map { item in
            MockClassificationObservation(identifier: item.identifier, confidence: item.confidence)
        }
    }
    
    // MARK: - Class labels de Food101 estándar
    private func getFood101ClassLabels() -> [String] {
        // Primeras 20 clases más comunes de Food101
        return [
            "apple_pie", "baby_back_ribs", "baklava", "beef_carpaccio", "beef_tartare",
            "beet_salad", "beignets", "bibimbap", "bread_pudding", "breakfast_burrito",
            "bruschetta", "caesar_salad", "cannoli", "caprese_salad", "carrot_cake",
            "ceviche", "cheese_plate", "cheesecake", "chicken_curry", "chicken_quesadilla",
            "chicken_wings", "chocolate_cake", "chocolate_mousse", "churros", "clam_chowder",
            "club_sandwich", "crab_cakes", "creme_brulee", "croque_madame", "cup_cakes",
            "deviled_eggs", "donuts", "dumplings", "edamame", "eggs_benedict",
            "escargots", "falafel", "filet_mignon", "fish_and_chips", "foie_gras",
            "french_fries", "french_onion_soup", "french_toast", "fried_calamari", "fried_rice",
            "frozen_yogurt", "garlic_bread", "gnocchi", "greek_salad", "grilled_cheese_sandwich",
            "grilled_salmon", "guacamole", "gyoza", "hamburger", "hot_and_sour_soup",
            "hot_dog", "huevos_rancheros", "hummus", "ice_cream", "lasagna",
            "lobster_bisque", "lobster_roll_sandwich", "macaroni_and_cheese", "macarons", "miso_soup",
            "mussels", "nachos", "omelette", "onion_rings", "oysters",
            "pad_thai", "paella", "pancakes", "panna_cotta", "peking_duck",
            "pho", "pizza", "pork_chop", "poutine", "prime_rib",
            "pulled_pork_sandwich", "ramen", "ravioli", "red_velvet_cake", "risotto",
            "samosa", "sashimi", "scallops", "seaweed_salad", "shrimp_and_grits",
            "spaghetti_bolognese", "spaghetti_carbonara", "spring_rolls", "steak", "strawberry_shortcake",
            "sushi", "tacos", "takoyaki", "tiramisu", "tuna_tartare",
            "waffles"
        ]
    }
    
    // MARK: - Resto de métodos auxiliares...
    private func findModelInBundle() -> URL? {
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
        
        print("🔍 DEBUG: Listando archivos ML en bundle...")
        if let bundlePath = Bundle.main.resourcePath {
            let fileManager = FileManager.default
            do {
                let files = try fileManager.contentsOfDirectory(atPath: bundlePath)
                let mlFiles = files.filter { $0.hasSuffix(".mlmodel") || $0.hasSuffix(".mlmodelc") }
                for file in mlFiles {
                    print("   📄 \(file)")
                }
            } catch {
                print("   ❌ Error: \(error)")
            }
        }
        
        return nil
    }
    
    private func loadFallbackModel() {
        print("🔄 Cargando modelo de fallback...")
        isUsingRealModel = false
    }
    
    private func performFallbackAnalysis(cgImage: CGImage) async throws -> FoodAnalysisResult {
        print("🚨 Ejecutando análisis de fallback...")
        // Tu implementación actual de fallback...
        
        let insights: [HealthInsight] = [
            HealthInsight(
                title: "⚠️ Análisis Fallback",
                description: "No se pudo usar el modelo personalizado. Usando análisis alternativo.",
                category: .nutrition,
                severity: .warning
            )
        ]
        
        return FoodAnalysisResult(
            foodName: "Alimento No Identificado",
            confidence: 0.1,
            nutritionalInfo: nutritionalDatabase.getNutritionalInfo(for: "Alimento Genérico"),
            healthInsights: insights
        )
    }
    
    // MARK: - Métodos auxiliares existentes (mantener los que ya tienes)
    private func handleCoreMLFeatureResults(_ results: [VNCoreMLFeatureValueObservation], continuation: CheckedContinuation<FoodAnalysisResult?, any Error>) {
        guard !results.isEmpty else {
            print("❌ No hay resultados CoreML")
            continuation.resume(returning: nil)
            return
        }
        
        for (index, result) in results.enumerated() {
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
                    let result = self.createFinalResult(from: classifications, analysisType: "Modelo Food101 (MultiArray)")
                    continuation.resume(returning: result)
                    return
                }
                
            } else if featureValue.dictionaryValue != nil {
                print("   📚 Dictionary detectado")
                
                // Acceder al diccionario de forma segura
                if let dictionary = featureValue.dictionaryValue as? [AnyHashable: NSNumber] {
                    // Convertir Dictionary a clasificaciones
                    if let classifications = convertDictionaryToClassifications(dictionary) {
                        let result = self.createFinalResult(from: classifications, analysisType: "Modelo Food101 (Dictionary)")
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
    
    private func convertDictionaryToClassifications(_ dictionary: [AnyHashable: NSNumber]) -> [VNClassificationObservation]? {
        var classifications: [(identifier: String, confidence: Float)] = []
        
        for (key, value) in dictionary {
            if let keyString = key as? String {
                let confidence = value.floatValue
                if confidence > Food101Config.minimumConfidence {
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
    
    private func createFinalResult(from results: [VNClassificationObservation], analysisType: String) -> FoodAnalysisResult {
        // Tu implementación actual...
        let topResult = results.first!
        let foodInfo = mapIdentifierToSpanish(identifier: topResult.identifier)
        let nutritionalInfo = nutritionalDatabase.getNutritionalInfo(for: foodInfo.spanishName)
        
        let insights: [HealthInsight] = [
            HealthInsight(
                title: "🤖 \(analysisType)",
                description: "Confianza: \(String(format: "%.1f", topResult.confidence * 100))%",
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
        // Tu implementación existente...
        let mappings: [String: (spanish: String, category: String)] = [
            "pizza": ("Pizza", "Comida Italiana"),
            "hamburger": ("Hamburguesa", "Comida Rápida"),
            "chicken_wings": ("Alitas de Pollo", "Proteína"),
            "french_fries": ("Papas Fritas", "Acompañamiento"),
            "chocolate_cake": ("Pastel de Chocolate", "Postre"),
            "sushi": ("Sushi", "Comida Japonesa"),
            // Agregar más mapeos según tus necesidades
        ]
        
        let clean_identifier = identifier.lowercased().replacingOccurrences(of: "_", with: " ")
        
        if let mapped = mappings[identifier.lowercased()] {
            return (identifier, mapped.spanish, mapped.category)
        }
        
        return (identifier, clean_identifier.capitalized, "Comida")
    }
    
    // MARK: - Debugging del Bundle
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
                    let sizeInMB = Double(fileSize) / (1024 * 1024)
                    print("      📏 Tamaño: \(String(format: "%.2f", sizeInMB)) MB")
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

// MARK: - Mock Classification mantenido
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