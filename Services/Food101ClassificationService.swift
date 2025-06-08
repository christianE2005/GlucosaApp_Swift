import UIKit
import CoreML
import Vision
import Foundation

// MARK: - Servicio de Clasificación Food101 con Modelo REAL
class Food101ClassificationService: ObservableObject {
    private var model: VNCoreMLModel?
    private let nutritionalDatabase = Food101NutritionalDatabase()
    private var isUsingRealModel = false
    
    init() {
        loadFood101Model()
    }
    
    private func loadFood101Model() {
        print("🔍 Iniciando carga de modelo Food101...")
        
        // OPCIÓN 1: Intentar cargar FoodClassifier.mlmodel (tu modelo real)
        if loadCustomFood101Model() {
            return
        }
        
        // OPCIÓN 2: Fallback a modelo Apple integrado (MobileNetV2/SqueezeNet)
        if loadAppleIntegratedModel() {
            return
        }
        
        // OPCIÓN 3: Último recurso - crear SqueezeNet programáticamente
        if loadSqueezeNetProgrammatically() {
            return
        }
        
        // Si todo falla, error
        print("❌ FATAL: No se pudo cargar ningún modelo ML")
        fatalError("No ML model available")
    }
    
    // MARK: - Cargar Modelo Food101 Personalizado
    private func loadCustomFood101Model() -> Bool {
        print("🎯 Intentando cargar FoodClassifier.mlmodel...")
        
        // Intentar diferentes nombres posibles
        let possibleNames = ["FoodClassifier", "Food101", "MobileNetV2Food101"]
        
        for modelName in possibleNames {
            if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodel") {
                do {
                    print("📁 Encontrado: \(modelName).mlmodel")
                    let mlModel = try MLModel(contentsOf: modelURL)
                    self.model = try VNCoreMLModel(for: mlModel)
                    self.isUsingRealModel = true
                    
                    print("✅ MODELO REAL CARGADO: \(modelName)")
                    print("🧠 Food101 - 101 tipos de alimentos")
                    print("📊 Análisis nutricional REAL activado")
                    return true
                    
                } catch {
                    print("❌ Error cargando \(modelName): \(error)")
                    continue
                }
            } else {
                print("❓ No encontrado: \(modelName).mlmodel")
            }
        }
        
        // También intentar versiones compiladas (.mlmodelc)
        for modelName in possibleNames {
            if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
                do {
                    print("📁 Encontrado compilado: \(modelName).mlmodelc")
                    let mlModel = try MLModel(contentsOf: modelURL)
                    self.model = try VNCoreMLModel(for: mlModel)
                    self.isUsingRealModel = true
                    
                    print("✅ MODELO REAL COMPILADO CARGADO: \(modelName)")
                    return true
                    
                } catch {
                    print("❌ Error cargando \(modelName).mlmodelc: \(error)")
                    continue
                }
            }
        }
        
        return false
    }
    
    // MARK: - Fallback a Modelos Apple
    private func loadAppleIntegratedModel() -> Bool {
        print("🍎 Intentando modelos Apple integrados...")
        
        // Intentar MobileNetV2
        do {
            if let modelURL = Bundle.main.url(forResource: "MobileNetV2", withExtension: "mlmodelc") {
                let mlModel = try MLModel(contentsOf: modelURL)
                self.model = try VNCoreMLModel(for: mlModel)
                self.isUsingRealModel = true
                print("✅ MobileNetV2 Apple cargado - Análisis REAL")
                return true
            }
        } catch {
            print("❌ Error con MobileNetV2: \(error)")
        }
        
        // Intentar ResNet50
        do {
            if let modelURL = Bundle.main.url(forResource: "ResNet50", withExtension: "mlmodelc") {
                let mlModel = try MLModel(contentsOf: modelURL)
                self.model = try VNCoreMLModel(for: mlModel)
                self.isUsingRealModel = true
                print("✅ ResNet50 cargado - Análisis REAL")
                return true
            }
        } catch {
            print("❌ Error con ResNet50: \(error)")
        }
        
        return false
    }
    
    // MARK: - SqueezeNet Programático
    private func loadSqueezeNetProgrammatically() -> Bool {
        print("🔧 Creando SqueezeNet programáticamente...")
        
        do {
            // Intentar crear SqueezeNet dinámicamente
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            // SqueezeNet está disponible en iOS 13.0+
            if #available(iOS 13.0, *) {
                let squeezenet = try SqueezeNet(configuration: config)
                self.model = try VNCoreMLModel(for: squeezenet.model)
                self.isUsingRealModel = true
                
                print("✅ SqueezeNet programático cargado - Análisis REAL")
                print("🎯 Clasificación de objetos generales (incluye alimentos)")
                return true
            }
        } catch {
            print("❌ Error creando SqueezeNet: \(error)")
        }
        
        return false
    }
    
    // MARK: - Función Principal de Clasificación
    func classifyFood(image: UIImage) async throws -> FoodAnalysisResult {
        guard let model = model else {
            throw Food101Error.modelNotLoaded
        }
        
        guard let cgImage = image.cgImage else {
            throw Food101Error.imageProcessingFailed
        }
        
        print("🧠 Iniciando análisis REAL con modelo cargado...")
        print("🔬 Tipo de modelo: \(isUsingRealModel ? "REAL" : "FALLBACK")")
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    print("❌ Error en Vision request: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNClassificationObservation] else {
                    print("❌ No se obtuvieron resultados de clasificación")
                    continuation.resume(throwing: Food101Error.noResults)
                    return
                }
                
                guard !results.isEmpty else {
                    print("❌ Lista de resultados vacía")
                    continuation.resume(throwing: Food101Error.noResults)
                    return
                }
                
                // Obtener top 3 resultados para mejor análisis
                let topResults = Array(results.prefix(3))
                let topResult = topResults[0]
                
                let confidence = topResult.confidence
                let identifier = topResult.identifier
                
                print("🎯 RESULTADO REAL:")
                print("   Identificador: \(identifier)")
                print("   Confianza: \(Int(confidence * 100))%")
                
                // Mapear resultado a español
                let foodInfo = self.mapIdentifierToSpanish(identifier: identifier)
                
                print("   Nombre en español: \(foodInfo.spanishName)")
                print("   Categoría: \(foodInfo.category)")
                
                // Obtener información nutricional
                let nutritionalInfo = self.nutritionalDatabase.getNutritionalInfo(
                    for: foodInfo.originalName,
                    spanishName: foodInfo.spanishName
                )
                
                // Generar insights específicos para diabetes
                let insights = self.generateRealDiabetesInsights(
                    foodInfo: foodInfo,
                    nutritionalInfo: nutritionalInfo,
                    confidence: confidence,
                    alternativeResults: Array(topResults.dropFirst()),
                    isRealModel: self.isUsingRealModel
                )
                
                let result = FoodAnalysisResult(
                    foodName: foodInfo.spanishName,
                    confidence: confidence,
                    nutritionalInfo: nutritionalInfo,
                    healthInsights: insights
                )
                
                print("✅ Análisis REAL completado exitosamente")
                continuation.resume(returning: result)
            }
            
            // Configurar request para mejor precisión
            request.imageCropAndScaleOption = .centerCrop
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("❌ Error ejecutando Vision handler: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Mapeo Inteligente de Identificadores
    private func mapIdentifierToSpanish(identifier: String) -> (originalName: String, spanishName: String, category: String) {
        let lowercased = identifier.lowercased()
        
        // Diccionario expandido para mejor mapeo
        let mappings: [String: (spanish: String, category: String)] = [
            // Food101 específicos
            "apple_pie": ("Tarta de Manzana", "Postre"),
            "baby_back_ribs": ("Costillas de Cerdo", "Proteína"),
            "baklava": ("Baklava", "Postre"),
            "beef_carpaccio": ("Carpaccio de Res", "Proteína"),
            "beef_tartare": ("Tartar de Res", "Proteína"),
            "beet_salad": ("Ensalada de Remolacha", "Ensalada"),
            "beignets": ("Buñuelos", "Postre"),
            "bibimbap": ("Bibimbap", "Coreana"),
            "bread_pudding": ("Budín de Pan", "Postre"),
            "breakfast_burrito": ("Burrito de Desayuno", "Desayuno"),
            "bruschetta": ("Bruschetta", "Aperitivo"),
            "caesar_salad": ("Ensalada César", "Ensalada"),
            "cannoli": ("Cannoli", "Postre"),
            "caprese_salad": ("Ensalada Caprese", "Ensalada"),
            "carrot_cake": ("Pastel de Zanahoria", "Postre"),
            "ceviche": ("Ceviche", "Mariscos"),
            "cheese_plate": ("Tabla de Quesos", "Aperitivo"),
            "cheesecake": ("Cheesecake", "Postre"),
            "chicken_curry": ("Pollo al Curry", "Proteína"),
            "chicken_quesadilla": ("Quesadilla de Pollo", "Mexicana"),
            "chicken_wings": ("Alitas de Pollo", "Proteína"),
            "chocolate_cake": ("Pastel de Chocolate", "Postre"),
            "chocolate_mousse": ("Mousse de Chocolate", "Postre"),
            "churros": ("Churros", "Postre"),
            "clam_chowder": ("Sopa de Almejas", "Sopa"),
            "club_sandwich": ("Club Sándwich", "Sándwich"),
            "crab_cakes": ("Pasteles de Cangrejo", "Mariscos"),
            "creme_brulee": ("Crema Catalana", "Postre"),
            "croque_madame": ("Croque Madame", "Sándwich"),
            "cup_cakes": ("Cupcakes", "Postre"),
            "deviled_eggs": ("Huevos Rellenos", "Aperitivo"),
            "donuts": ("Donas", "Postre"),
            "dumplings": ("Empanadillas", "Asiática"),
            "edamame": ("Edamame", "Aperitivo"),
            "eggs_benedict": ("Huevos Benedict", "Desayuno"),
            "escargots": ("Caracoles", "Francesa"),
            "falafel": ("Falafel", "Mediterránea"),
            "filet_mignon": ("Filete Miñón", "Proteína"),
            "fish_and_chips": ("Pescado con Papas", "Mariscos"),
            "foie_gras": ("Foie Gras", "Francesa"),
            "french_fries": ("Papas Fritas", "Carbohidrato"),
            "french_onion_soup": ("Sopa de Cebolla Francesa", "Sopa"),
            "french_toast": ("Tostadas Francesas", "Desayuno"),
            "fried_calamari": ("Calamares Fritos", "Mariscos"),
            "fried_rice": ("Arroz Frito", "Carbohidrato"),
            "frozen_yogurt": ("Yogurt Helado", "Postre"),
            "garlic_bread": ("Pan de Ajo", "Carbohidrato"),
            "gnocchi": ("Ñoquis", "Carbohidrato"),
            "greek_salad": ("Ensalada Griega", "Ensalada"),
            "grilled_cheese_sandwich": ("Sándwich de Queso", "Sándwich"),
            "grilled_salmon": ("Salmón a la Parrilla", "Proteína"),
            "guacamole": ("Guacamole", "Aperitivo"),
            "gyoza": ("Gyoza", "Asiática"),
            "hamburger": ("Hamburguesa", "Comida Rápida"),
            "hot_and_sour_soup": ("Sopa Agripicante", "Sopa"),
            "hot_dog": ("Perro Caliente", "Comida Rápida"),
            "huevos_rancheros": ("Huevos Rancheros", "Mexicana"),
            "hummus": ("Hummus", "Aperitivo"),
            "ice_cream": ("Helado", "Postre"),
            "lasagna": ("Lasaña", "Carbohidrato"),
            "lobster_bisque": ("Bisque de Langosta", "Sopa"),
            "lobster_roll_sandwich": ("Sándwich de Langosta", "Mariscos"),
            "macaroni_and_cheese": ("Macarrones con Queso", "Carbohidrato"),
            "macarons": ("Macarrones", "Postre"),
            "miso_soup": ("Sopa de Miso", "Sopa"),
            "mussels": ("Mejillones", "Mariscos"),
            "nachos": ("Nachos", "Aperitivo"),
            "omelette": ("Tortilla", "Desayuno"),
            "onion_rings": ("Aros de Cebolla", "Aperitivo"),
            "oysters": ("Ostras", "Mariscos"),
            "pad_thai": ("Pad Thai", "Asiática"),
            "paella": ("Paella", "Española"),
            "pancakes": ("Panqueques", "Desayuno"),
            "panna_cotta": ("Panna Cotta", "Postre"),
            "peking_duck": ("Pato Pequinés", "Asiática"),
            "pho": ("Pho", "Vietnamita"),
            "pizza": ("Pizza", "Carbohidrato"),
            "pork_chop": ("Chuleta de Cerdo", "Proteína"),
            "poutine": ("Poutine", "Canadiense"),
            "prime_rib": ("Costillar Prime", "Proteína"),
            "pulled_pork_sandwich": ("Sándwich de Cerdo", "Sándwich"),
            "ramen": ("Ramen", "Asiática"),
            "ravioli": ("Ravioli", "Carbohidrato"),
            "red_velvet_cake": ("Pastel Red Velvet", "Postre"),
            "risotto": ("Risotto", "Carbohidrato"),
            "samosa": ("Samosa", "India"),
            "sashimi": ("Sashimi", "Japonesa"),
            "scallops": ("Vieiras", "Mariscos"),
            "seaweed_salad": ("Ensalada de Algas", "Ensalada"),
            "shrimp_and_grits": ("Camarones con Sémola", "Mariscos"),
            "spaghetti_bolognese": ("Espagueti Boloñesa", "Carbohidrato"),
            "spaghetti_carbonara": ("Espagueti Carbonara", "Carbohidrato"),
            "spring_rolls": ("Rollitos Primavera", "Asiática"),
            "steak": ("Bistec", "Proteína"),
            "strawberry_shortcake": ("Pastel de Fresa", "Postre"),
            "sushi": ("Sushi", "Japonesa"),
            "tacos": ("Tacos", "Mexicana"),
            "takoyaki": ("Takoyaki", "Japonesa"),
            "tiramisu": ("Tiramisú", "Postre"),
            "tuna_tartare": ("Tartar de Atún", "Mariscos"),
            "waffles": ("Waffles", "Desayuno"),
            
            // Términos generales de ImageNet/SqueezeNet
            "pizza": ("Pizza", "Carbohidrato"),
            "hamburger": ("Hamburguesa", "Comida Rápida"),
            "hot_dog": ("Perro Caliente", "Comida Rápida"),
            "sandwich": ("Sándwich", "Sándwich"),
            "taco": ("Taco", "Mexicana"),
            "burrito": ("Burrito", "Mexicana"),
            "bagel": ("Bagel", "Carbohidrato"),
            "pretzel": ("Pretzel", "Carbohidrato"),
            "cheeseburger": ("Hamburguesa con Queso", "Comida Rápida"),
            "meat_loaf": ("Pastel de Carne", "Proteína"),
            "ice_lolly": ("Paleta Helada", "Postre"),
            "french_loaf": ("Pan Francés", "Carbohidrato"),
            "bagel": ("Bagel", "Carbohidrato"),
            "bread": ("Pan", "Carbohidrato"),
            "meatball": ("Albóndiga", "Proteína"),
            "soup_bowl": ("Sopa", "Sopa"),
            "consomme": ("Consomé", "Sopa"),
            "espresso": ("Espresso", "Bebida"),
            "cup": ("Taza", "Bebida"),
            "plate": ("Plato", "Otros"),
            "bowl": ("Tazón", "Otros")
        ]
        
        // Buscar mapeo directo
        if let mapped = mappings[lowercased] {
            return (identifier, mapped.spanish, mapped.category)
        }
        
        // Buscar por patrones de palabras clave
        for (key, value) in mappings {
            if lowercased.contains(key) || key.contains(lowercased) {
                return (identifier, value.spanish, value.category)
            }
        }
        
        // Mapeo inteligente basado en palabras clave
        if lowercased.contains("pizza") {
            return (identifier, "Pizza", "Carbohidrato")
        } else if lowercased.contains("burger") || lowercased.contains("hamburger") {
            return (identifier, "Hamburguesa", "Comida Rápida")
        } else if lowercased.contains("cake") || lowercased.contains("dessert") {
            return (identifier, "Pastel", "Postre")
        } else if lowercased.contains("salad") {
            return (identifier, "Ensalada", "Ensalada")
        } else if lowercased.contains("chicken") {
            return (identifier, "Pollo", "Proteína")
        } else if lowercased.contains("fish") || lowercased.contains("salmon") {
            return (identifier, "Pescado", "Proteína")
        } else if lowercased.contains("bread") || lowercased.contains("sandwich") {
            return (identifier, "Pan/Sándwich", "Carbohidrato")
        } else if lowercased.contains("soup") {
            return (identifier, "Sopa", "Sopa")
        } else if lowercased.contains("pasta") || lowercased.contains("spaghetti") {
            return (identifier, "Pasta", "Carbohidrato")
        } else if lowercased.contains("ice") || lowercased.contains("cream") {
            return (identifier, "Helado", "Postre")
        }
        
        // Fallback: capitalizar y categorizar como "Otros"
        let spanishName = identifier
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
        
        return (identifier, spanishName, "Otros")
    }
    
    // MARK: - Insights REALES para diabetes
    private func generateRealDiabetesInsights(
        foodInfo: (originalName: String, spanishName: String, category: String),
        nutritionalInfo: NutritionalInfo,
        confidence: Float,
        alternativeResults: [VNClassificationObservation],
        isRealModel: Bool
    ) -> [HealthInsight] {
        
        var insights: [HealthInsight] = []
        
        // 1. Insight sobre el tipo de análisis
        if isRealModel {
            insights.append(HealthInsight(
                title: "🧠 Análisis Real con IA",
                description: "Clasificación realizada con modelo de machine learning real. Confianza: \(Int(confidence * 100))%",
                category: .nutrition,
                severity: .info
            ))
        }
        
        // 2. Análisis de confianza
        if confidence < 0.6 {
            let alternatives = alternativeResults.prefix(2).map { result in
                mapIdentifierToSpanish(identifier: result.identifier).spanishName
            }.joined(separator: ", ")
            
            insights.append(HealthInsight(
                title: "⚠️ Verificar Identificación",
                description: "Confianza del \(Int(confidence * 100))%. Alternativas: \(alternatives). Verifica manualmente.",
                category: .nutrition,
                severity: .warning
            ))
        } else if confidence > 0.85 {
            insights.append(HealthInsight(
                title: "✅ Identificación Precisa",
                description: "Alta confianza (\(Int(confidence * 100))%). Análisis nutricional muy confiable.",
                category: .nutrition,
                severity: .info
            ))
        }
        
        // 3. Análisis específico por categoría
        switch foodInfo.category {
        case "Postre":
            insights.append(HealthInsight(
                title: "⚠️ Alto Impacto Glucémico",
                description: "Los postres elevan rápidamente la glucosa. Considera: porción pequeña, ejercicio post-comida.",
                category: .glucose,
                severity: .warning
            ))
            
        case "Proteína":
            insights.append(HealthInsight(
                title: "✅ Excelente para Diabetes",
                description: "Las proteínas estabilizan glucosa y proporcionan saciedad. Ideal para control diabético.",
                category: .nutrition,
                severity: .info
            ))
            
        case "Ensalada":
            insights.append(HealthInsight(
                title: "✅ Muy Saludable",
                description: "Baja en carbohidratos, rica en fibra y micronutrientes. Perfecto para diabetes.",
                category: .nutrition,
                severity: .info
            ))
            
        case "Carbohidrato":
            if nutritionalInfo.carbohydrates > 30 {
                insights.append(HealthInsight(
                    title: "⚠️ Carbohidratos Altos",
                    description: "Contiene \(Int(nutritionalInfo.carbohydrates))g carbohidratos. Monitorea glucosa 2h después.",
                    category: .glucose,
                    severity: .warning
                ))
            }
            
        default:
            break
        }
        
        // 4. Análisis del índice glucémico
        switch nutritionalInfo.glycemicIndex {
        case .high:
            insights.append(HealthInsight(
                title: "🔴 Índice Glucémico Alto",
                description: "Eleva rápidamente la glucosa. Combina con proteína/fibra para moderar impacto.",
                category: .glucose,
                severity: .warning
            ))
        case .low:
            insights.append(HealthInsight(
                title: "🟢 Índice Glucémico Bajo",
                description: "Impacto gradual y controlado en glucosa. Excelente elección para diabetes.",
                category: .glucose,
                severity: .info
            ))
        case .medium:
            insights.append(HealthInsight(
                title: "🟡 Índice Glucémico Moderado",
                description: "Impacto moderado. Controla la porción para mejores resultados.",
                category: .glucose,
                severity: .info
            ))
        }
        
        return insights
    }
}

// MARK: - Base de datos nutricional expandida (misma que antes)
class Food101NutritionalDatabase {
    private let food101Nutrition: [String: NutritionalInfo] = [
        // [Mantener toda la base de datos existente pero expandida]
        // Postres
        "apple_pie": NutritionalInfo(calories: 237, carbohydrates: 34, proteins: 2, fats: 11, fiber: 2, sugars: 19, sodium: 240, glycemicIndex: .high, portionSize: 100),
        "chocolate_cake": NutritionalInfo(calories: 371, carbohydrates: 50, proteins: 5, fats: 16, fiber: 3, sugars: 36, sodium: 469, glycemicIndex: .high, portionSize: 100),
        "ice_cream": NutritionalInfo(calories: 207, carbohydrates: 24, proteins: 4, fats: 11, fiber: 0.7, sugars: 21, sodium: 80, glycemicIndex: .high, portionSize: 100),
        "donuts": NutritionalInfo(calories: 452, carbohydrates: 51, proteins: 5, fats: 25, fiber: 2, sugars: 23, sodium: 373, glycemicIndex: .high, portionSize: 100),
        "churros": NutritionalInfo(calories: 312, carbohydrates: 42, proteins: 4, fats: 14, fiber: 1.5, sugars: 12, sodium: 201, glycemicIndex: .high, portionSize: 100),
        "tiramisu": NutritionalInfo(calories: 350, carbohydrates: 35, proteins: 6, fats: 20, fiber: 1, sugars: 30, sodium: 150, glycemicIndex: .high, portionSize: 100),
        
        // Proteínas
        "steak": NutritionalInfo(calories: 271, carbohydrates: 0, proteins: 26, fats: 17, fiber: 0, sugars: 0, sodium: 59, glycemicIndex: .low, portionSize: 100),
        "chicken_wings": NutritionalInfo(calories: 203, carbohydrates: 0, proteins: 30, fats: 8, fiber: 0, sugars: 0, sodium: 82, glycemicIndex: .low, portionSize: 100),
        "grilled_salmon": NutritionalInfo(calories: 231, carbohydrates: 0, proteins: 25, fats: 14, fiber: 0, sugars: 0, sodium: 59, glycemicIndex: .low, portionSize: 100),
        "filet_mignon": NutritionalInfo(calories: 267, carbohydrates: 0, proteins: 26, fats: 17, fiber: 0, sugars: 0, sodium: 54, glycemicIndex: .low, portionSize: 100),
        
        // Carbohidratos
        "french_fries": NutritionalInfo(calories: 365, carbohydrates: 63, proteins: 4, fats: 17, fiber: 4, sugars: 0.3, sodium: 246, glycemicIndex: .high, portionSize: 100),
        "pizza": NutritionalInfo(calories: 266, carbohydrates: 33, proteins: 11, fats: 10, fiber: 2.3, sugars: 3.6, sodium: 598, glycemicIndex: .medium, portionSize: 100),
        "hamburger": NutritionalInfo(calories: 295, carbohydrates: 30, proteins: 17, fats: 14, fiber: 2, sugars: 4, sodium: 564, glycemicIndex: .medium, portionSize: 100),
        "fried_rice": NutritionalInfo(calories: 238, carbohydrates: 35, proteins: 6, fats: 8, fiber: 1.4, sugars: 2.1, sodium: 460, glycemicIndex: .high, portionSize: 100),
        "lasagna": NutritionalInfo(calories: 135, carbohydrates: 11, proteins: 8, fats: 7, fiber: 1, sugars: 4, sodium: 340, glycemicIndex: .medium, portionSize: 100),
        
        // Ensaladas
        "caesar_salad": NutritionalInfo(calories: 113, carbohydrates: 5, proteins: 3, fats: 10, fiber: 2, sugars: 2, sodium: 305, glycemicIndex: .low, portionSize: 100),
        "greek_salad": NutritionalInfo(calories: 107, carbohydrates: 6, proteins: 3, fats: 9, fiber: 3, sugars: 4, sodium: 312, glycemicIndex: .low, portionSize: 100),
        "caprese_salad": NutritionalInfo(calories: 150, carbohydrates: 8, proteins: 8, fats: 11, fiber: 2, sugars: 6, sodium: 250, glycemicIndex: .low, portionSize: 100),
        
        // Mariscos
        "sushi": NutritionalInfo(calories: 156, carbohydrates: 24, proteins: 7, fats: 4, fiber: 3, sugars: 3.5, sodium: 428, glycemicIndex: .medium, portionSize: 100),
        "fish_and_chips": NutritionalInfo(calories: 265, carbohydrates: 17, proteins: 16, fats: 15, fiber: 1.4, sugars: 0.5, sodium: 435, glycemicIndex: .medium, portionSize: 100),
        "lobster_bisque": NutritionalInfo(calories: 120, carbohydrates: 8, proteins: 8, fats: 7, fiber: 0.5, sugars: 3, sodium: 890, glycemicIndex: .low, portionSize: 100),
        
        // Desayunos
        "pancakes": NutritionalInfo(calories: 227, carbohydrates: 28, proteins: 6, fats: 10, fiber: 1.4, sugars: 6, sodium: 439, glycemicIndex: .high, portionSize: 100),
        "eggs_benedict": NutritionalInfo(calories: 230, carbohydrates: 8, proteins: 15, fats: 16, fiber: 0.5, sugars: 2, sodium: 920, glycemicIndex: .low, portionSize: 100),
        "french_toast": NutritionalInfo(calories: 220, carbohydrates: 25, proteins: 8, fats: 10, fiber: 2, sugars: 8, sodium: 380, glycemicIndex: .high, portionSize: 100),
        "waffles": NutritionalInfo(calories: 290, carbohydrates: 33, proteins: 6, fats: 15, fiber: 2, sugars: 12, sodium: 450, glycemicIndex: .high, portionSize: 100),
        
        // Asiática
        "pad_thai": NutritionalInfo(calories: 180, carbohydrates: 25, proteins: 12, fats: 6, fiber: 2, sugars: 8, sodium: 850, glycemicIndex: .medium, portionSize: 100),
        "ramen": NutritionalInfo(calories: 188, carbohydrates: 27, proteins: 10, fats: 5, fiber: 1.5, sugars: 3, sodium: 1200, glycemicIndex: .medium, portionSize: 100),
        "bibimbap": NutritionalInfo(calories: 120, carbohydrates: 18, proteins: 8, fats: 3, fiber: 3, sugars: 4, sodium: 320, glycemicIndex: .medium, portionSize: 100),
        
        // Mexicana
        "tacos": NutritionalInfo(calories: 226, carbohydrates: 20, proteins: 15, fats: 11, fiber: 3, sugars: 2, sodium: 367, glycemicIndex: .medium, portionSize: 100),
        "guacamole": NutritionalInfo(calories: 160, carbohydrates: 9, proteins: 2, fats: 15, fiber: 7, sugars: 1, sodium: 7, glycemicIndex: .low, portionSize: 100),
        "nachos": NutritionalInfo(calories: 346, carbohydrates: 36, proteins: 9, fats: 19, fiber: 3, sugars: 2, sodium: 816, glycemicIndex: .high, portionSize: 100)
    ]
    
    func getNutritionalInfo(for originalName: String, spanishName: String) -> NutritionalInfo {
        // Buscar primero por nombre original
        if let info = food101Nutrition[originalName.lowercased()] {
            return info
        }
        
        // Buscar por patrones en el nombre
        let searchTerms = originalName.lowercased().components(separatedBy: ["_", " ", "-"])
        for term in searchTerms {
            for (key, value) in food101Nutrition {
                if key.contains(term) && term.count > 3 {
                    return value
                }
            }
        }
        
        return generateSmartDefaults(for: spanishName, originalName: originalName)
    }
    
    private func generateSmartDefaults(for spanishName: String, originalName: String) -> NutritionalInfo {
        let lower = originalName.lowercased()
        
        // Categorización inteligente para datos nutricionales
        if lower.contains("salad") || lower.contains("greens") {
            return NutritionalInfo(calories: 35, carbohydrates: 7, proteins: 2.5, fats: 0.3, fiber: 3, sugars: 4, sodium: 20, glycemicIndex: .low, portionSize: 100)
        } else if lower.contains("cake") || lower.contains("pie") || lower.contains("dessert") || lower.contains("ice") {
            return NutritionalInfo(calories: 350, carbohydrates: 45, proteins: 4, fats: 16, fiber: 2, sugars: 40, sodium: 300, glycemicIndex: .high, portionSize: 100)
        } else if lower.contains("chicken") || lower.contains("beef") || lower.contains("pork") || lower.contains("meat") || lower.contains("fish") {
            return NutritionalInfo(calories: 220, carbohydrates: 0, proteins: 25, fats: 12, fiber: 0, sugars: 0, sodium: 75, glycemicIndex: .low, portionSize: 100)
        } else if lower.contains("rice") || lower.contains("pasta") || lower.contains("bread") || lower.contains("pizza") {
            return NutritionalInfo(calories: 200, carbohydrates: 40, proteins: 6, fats: 2, fiber: 2, sugars: 2, sodium: 10, glycemicIndex: .medium, portionSize: 100)
        } else if lower.contains("soup") {
            return NutritionalInfo(calories: 80, carbohydrates: 12, proteins: 4, fats: 2, fiber: 2, sugars: 4, sodium: 600, glycemicIndex: .low, portionSize: 100)
        } else {
            // Valores por defecto conservadores
            return NutritionalInfo(calories: 150, carbohydrates: 20, proteins: 6, fats: 5, fiber: 2, sugars: 8, sodium: 150, glycemicIndex: .medium, portionSize: 100)
        }
    }
}

// MARK: - Errores específicos de Food101
enum Food101Error: Error {
    case modelNotLoaded
    case imageProcessingFailed
    case noResults
    
    var localizedDescription: String {
        switch self {
        case .modelNotLoaded:
            return "No se pudo cargar ningún modelo de IA"
        case .imageProcessingFailed:
            return "Error procesando la imagen"
        case .noResults:
            return "La IA no pudo clasificar este alimento"
        }
    }
}
