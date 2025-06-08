import UIKit
import CoreML
import Vision
import Foundation

// MARK: - Servicio de Clasificación Food101 con IA
class Food101ClassificationService: ObservableObject {
    private var model: VNCoreMLModel?
    private let nutritionalDatabase = Food101NutritionalDatabase()
    
    init() {
        loadFood101Model()
    }
    
    private func loadFood101Model() {
        guard let modelURL = Bundle.main.url(forResource: "FoodClassifier", withExtension: "mlmodel") else {
            print("❌ No se encontró FoodClassifier.mlmodel en el bundle")
            print("💡 Asegúrate de que el archivo esté incluido en el target del proyecto")
            return
        }
        
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            self.model = try VNCoreMLModel(for: mlModel)
            print("✅ Modelo Food101 cargado exitosamente")
            print("🧠 Listo para clasificar 101 tipos de alimentos")
        } catch {
            print("❌ Error cargando modelo Food101: \(error)")
        }
    }
    
    func classifyFood(image: UIImage) async throws -> FoodAnalysisResult {
        guard let model = model else {
            throw Food101Error.modelNotLoaded
        }
        
        guard let cgImage = image.cgImage else {
            throw Food101Error.imageProcessingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: Food101Error.noResults)
                    return
                }
                
                // Obtener top 3 resultados para mejor análisis
                let topResults = Array(results.prefix(3))
                
                guard let topResult = topResults.first else {
                    continuation.resume(throwing: Food101Error.noResults)
                    return
                }
                
                // Mapear resultado de Food101 a español
                let foodInfo = self.mapFood101ToSpanish(identifier: topResult.identifier)
                let confidence = topResult.confidence
                
                print("🍎 Alimento detectado: \(foodInfo.spanishName)")
                print("📊 Confianza: \(Int(confidence * 100))%")
                print("🏷️ Categoría: \(foodInfo.category)")
                
                // Obtener información nutricional
                let nutritionalInfo = self.nutritionalDatabase.getNutritionalInfo(
                    for: foodInfo.originalName,
                    spanishName: foodInfo.spanishName
                )
                
                // Generar insights específicos para diabetes
                let insights = self.generateDiabetesInsights(
                    foodInfo: foodInfo,
                    nutritionalInfo: nutritionalInfo,
                    confidence: confidence,
                    alternativeResults: Array(topResults.dropFirst())
                )
                
                let result = FoodAnalysisResult(
                    foodName: foodInfo.spanishName,
                    confidence: confidence,
                    nutritionalInfo: nutritionalInfo,
                    healthInsights: insights
                )
                
                continuation.resume(returning: result)
            }
            
            request.imageCropAndScaleOption = .centerCrop
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Mapeo Food101 a español con categorías
    private func mapFood101ToSpanish(identifier: String) -> (originalName: String, spanishName: String, category: String) {
        let food101ToSpanish: [String: (spanish: String, category: String)] = [
            // Frutas y postres
            "apple_pie": ("Tarta de Manzana", "Postre"),
            "baklava": ("Baklava", "Postre"),
            "bread_pudding": ("Budín de Pan", "Postre"),
            "chocolate_cake": ("Pastel de Chocolate", "Postre"),
            "chocolate_mousse": ("Mousse de Chocolate", "Postre"),
            "churros": ("Churros", "Postre"),
            "creme_brulee": ("Crema Catalana", "Postre"),
            "donuts": ("Donas", "Postre"),
            "ice_cream": ("Helado", "Postre"),
            "macarons": ("Macarrones", "Postre"),
            "tiramisu": ("Tiramisú", "Postre"),
            
            // Carnes y proteínas
            "baby_back_ribs": ("Costillas de Cerdo", "Proteína"),
            "beef_carpaccio": ("Carpaccio de Res", "Proteína"),
            "beef_tartare": ("Tartar de Res", "Proteína"),
            "chicken_curry": ("Pollo al Curry", "Proteína"),
            "chicken_wings": ("Alitas de Pollo", "Proteína"),
            "filet_mignon": ("Filete Miñón", "Proteína"),
            "grilled_salmon": ("Salmón a la Parrilla", "Proteína"),
            "lobster_bisque": ("Bisque de Langosta", "Proteína"),
            "pork_chop": ("Chuleta de Cerdo", "Proteína"),
            "prime_rib": ("Costillar Prime", "Proteína"),
            "steak": ("Bistec", "Proteína"),
            
            // Ensaladas y verduras
            "caesar_salad": ("Ensalada César", "Ensalada"),
            "caprese_salad": ("Ensalada Caprese", "Ensalada"),
            "greek_salad": ("Ensalada Griega", "Ensalada"),
            "seaweed_salad": ("Ensalada de Algas", "Ensalada"),
            
            // Carbohidratos y granos
            "french_fries": ("Papas Fritas", "Carbohidrato"),
            "fried_rice": ("Arroz Frito", "Carbohidrato"),
            "gnocchi": ("Ñoquis", "Carbohidrato"),
            "lasagna": ("Lasaña", "Carbohidrato"),
            "pad_thai": ("Pad Thai", "Carbohidrato"),
            "pizza": ("Pizza", "Carbohidrato"),
            "risotto": ("Risotto", "Carbohidrato"),
            "spaghetti_bolognese": ("Espagueti Boloñesa", "Carbohidrato"),
            "spaghetti_carbonara": ("Espagueti Carbonara", "Carbohidrato"),
            
            // Desayunos
            "breakfast_burrito": ("Burrito de Desayuno", "Desayuno"),
            "eggs_benedict": ("Huevos Benedict", "Desayuno"),
            "french_toast": ("Tostadas Francesas", "Desayuno"),
            "pancakes": ("Panqueques", "Desayuno"),
            "waffles": ("Waffles", "Desayuno"),
            
            // Aperitivos y snacks
            "bruschetta": ("Bruschetta", "Aperitivo"),
            "cheese_plate": ("Tabla de Quesos", "Aperitivo"),
            "deviled_eggs": ("Huevos Rellenos", "Aperitivo"),
            "hummus": ("Hummus", "Aperitivo"),
            "nachos": ("Nachos", "Aperitivo"),
            "oysters": ("Ostras", "Aperitivo"),
            "spring_rolls": ("Rollitos Primavera", "Aperitivo"),
            
            // Mariscos
            "clam_chowder": ("Sopa de Almejas", "Mariscos"),
            "crab_cakes": ("Pasteles de Cangrejo", "Mariscos"),
            "fish_and_chips": ("Pescado con Papas", "Mariscos"),
            "lobster_roll_sandwich": ("Sándwich de Langosta", "Mariscos"),
            "mussels": ("Mejillones", "Mariscos"),
            "scallops": ("Vieiras", "Mariscos"),
            "shrimp_and_grits": ("Camarones con Sémola", "Mariscos"),
            "sushi": ("Sushi", "Mariscos"),
            
            // Sopas
            "beet_salad": ("Ensalada de Remolacha", "Sopa"),
            "french_onion_soup": ("Sopa de Cebolla Francesa", "Sopa"),
            "miso_soup": ("Sopa de Miso", "Sopa"),
            "ramen": ("Ramen", "Sopa"),
            "tomato_soup": ("Sopa de Tomate", "Sopa"),
            
            // Comida rápida
            "hamburger": ("Hamburguesa", "Comida Rápida"),
            "hot_dog": ("Perro Caliente", "Comida Rápida"),
            
            // Internacional
            "bibimbap": ("Bibimbap", "Coreana"),
            "falafel": ("Falafel", "Mediterránea"),
            "paella": ("Paella", "Española"),
            "pho": ("Pho", "Vietnamita"),
            "tacos": ("Tacos", "Mexicana"),
        ]
        
        if let mapped = food101ToSpanish[identifier] {
            return (identifier, mapped.spanish, mapped.category)
        } else {
            // Para alimentos no mapeados, convertir formato y categorizar
            let spanishName = identifier
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
            
            // Categorización inteligente basada en patrones
            let category = categorizeUnknownFood(identifier)
            return (identifier, spanishName, category)
        }
    }
    
    private func categorizeUnknownFood(_ identifier: String) -> String {
        let lower = identifier.lowercased()
        
        if lower.contains("cake") || lower.contains("pie") || lower.contains("cookie") {
            return "Postre"
        } else if lower.contains("chicken") || lower.contains("beef") || lower.contains("pork") || lower.contains("meat") {
            return "Proteína"
        } else if lower.contains("salad") || lower.contains("greens") {
            return "Ensalada"
        } else if lower.contains("soup") || lower.contains("broth") {
            return "Sopa"
        } else if lower.contains("rice") || lower.contains("pasta") || lower.contains("bread") {
            return "Carbohidrato"
        } else if lower.contains("fish") || lower.contains("shrimp") || lower.contains("crab") {
            return "Mariscos"
        } else {
            return "Otros"
        }
    }
    
    // MARK: - Insights específicos para diabetes
    private func generateDiabetesInsights(
        foodInfo: (originalName: String, spanishName: String, category: String),
        nutritionalInfo: NutritionalInfo,
        confidence: Float,
        alternativeResults: [VNClassificationObservation]
    ) -> [HealthInsight] {
        
        var insights: [HealthInsight] = []
        
        // 1. Análisis de confianza de la IA
        if confidence < 0.6 {
            let alternatives = alternativeResults.prefix(2).map { result in
                mapFood101ToSpanish(identifier: result.identifier).spanishName
            }.joined(separator: ", ")
            
            insights.append(HealthInsight(
                title: "Verificar Identificación de IA",
                description: "La IA tiene \(Int(confidence * 100))% de confianza. Podría ser: \(alternatives). Verifica manualmente para mayor precisión.",
                category: .nutrition,
                severity: .warning
            ))
        } else if confidence > 0.85 {
            insights.append(HealthInsight(
                title: "Identificación Muy Precisa",
                description: "La IA está \(Int(confidence * 100))% segura de la identificación. Análisis nutricional confiable.",
                category: .nutrition,
                severity: .info
            ))
        }
        
        // 2. Análisis específico por categoría de alimento
        switch foodInfo.category {
        case "Postre":
            insights.append(HealthInsight(
                title: "⚠️ Alto Impacto Glucémico",
                description: "Los postres elevan rápidamente la glucosa. Considera: porción pequeña, combinación con proteína, ajuste de insulina.",
                category: .glucose,
                severity: .warning
            ))
            
        case "Carbohidrato":
            let carbLevel = nutritionalInfo.carbohydrates
            if carbLevel > 30 {
                insights.append(HealthInsight(
                    title: "Carbohidratos Altos",
                    description: "Contiene \(Int(carbLevel))g de carbohidratos. Controla la porción y considera el timing de medicación.",
                    category: .portion,
                    severity: .warning
                ))
            }
            
        case "Proteína":
            insights.append(HealthInsight(
                title: "✅ Excelente para Diabetes",
                description: "Las proteínas estabilizan la glucosa y proporcionan saciedad. Ideal para control glucémico.",
                category: .nutrition,
                severity: .info
            ))
            
        case "Ensalada":
            insights.append(HealthInsight(
                title: "✅ Muy Saludable",
                description: "Baja en carbohidratos, rica en fibra. Excelente para mantener niveles estables de glucosa.",
                category: .nutrition,
                severity: .info
            ))
            
        default:
            break
        }
        
        // 3. Análisis del índice glucémico
        switch nutritionalInfo.glycemicIndex {
        case .high:
            insights.append(HealthInsight(
                title: "⚠️ Índice Glucémico Alto",
                description: "Este alimento puede elevar rápidamente la glucosa. Combínalo con fibra o proteína para moderar el impacto.",
                category: .glucose,
                severity: .warning
            ))
        case .low:
            insights.append(HealthInsight(
                title: "✅ Índice Glucémico Bajo",
                description: "Impacto gradual en la glucosa. Excelente opción para el control diabético.",
                category: .glucose,
                severity: .info
            ))
        case .medium:
            insights.append(HealthInsight(
                title: "Índice Glucémico Moderado",
                description: "Impacto moderado en glucosa. Controla la porción para mejores resultados.",
                category: .glucose,
                severity: .info
            ))
        }
        
        // 4. Recomendaciones de timing
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        if foodInfo.category == "Postre" && currentHour > 18 {
            insights.append(HealthInsight(
                title: "Considera el Timing",
                description: "Los postres nocturnos pueden afectar la glucosa durante el sueño. Mejor consumir más temprano.",
                category: .timing,
                severity: .info
            ))
        }
        
        if foodInfo.category == "Carbohidrato" && currentHour < 12 {
            insights.append(HealthInsight(
                title: "Buen Timing para Carbohidratos",
                description: "Los carbohidratos matutinos se metabolizan mejor debido a la actividad diaria programada.",
                category: .timing,
                severity: .info
            ))
        }
        
        return insights
    }
}

// MARK: - Base de datos nutricional específica para Food101
class Food101NutritionalDatabase {
    private let food101Nutrition: [String: NutritionalInfo] = [
        // Postres (Alto IG)
        "apple_pie": NutritionalInfo(calories: 237, carbohydrates: 34, proteins: 2, fats: 11, fiber: 2, sugars: 19, sodium: 240, glycemicIndex: .high, portionSize: 100),
        "chocolate_cake": NutritionalInfo(calories: 371, carbohydrates: 50, proteins: 5, fats: 16, fiber: 3, sugars: 36, sodium: 469, glycemicIndex: .high, portionSize: 100),
        "ice_cream": NutritionalInfo(calories: 207, carbohydrates: 24, proteins: 4, fats: 11, fiber: 0.7, sugars: 21, sodium: 80, glycemicIndex: .high, portionSize: 100),
        "donuts": NutritionalInfo(calories: 452, carbohydrates: 51, proteins: 5, fats: 25, fiber: 2, sugars: 23, sodium: 373, glycemicIndex: .high, portionSize: 100),
        "churros": NutritionalInfo(calories: 312, carbohydrates: 42, proteins: 4, fats: 14, fiber: 1.5, sugars: 12, sodium: 201, glycemicIndex: .high, portionSize: 100),
        
        // Proteínas (Bajo IG)
        "steak": NutritionalInfo(calories: 271, carbohydrates: 0, proteins: 26, fats: 17, fiber: 0, sugars: 0, sodium: 59, glycemicIndex: .low, portionSize: 100),
        "chicken_wings": NutritionalInfo(calories: 203, carbohydrates: 0, proteins: 30, fats: 8, fiber: 0, sugars: 0, sodium: 82, glycemicIndex: .low, portionSize: 100),
        "grilled_salmon": NutritionalInfo(calories: 231, carbohydrates: 0, proteins: 25, fats: 14, fiber: 0, sugars: 0, sodium: 59, glycemicIndex: .low, portionSize: 100),
        "filet_mignon": NutritionalInfo(calories: 267, carbohydrates: 0, proteins: 26, fats: 17, fiber: 0, sugars: 0, sodium: 54, glycemicIndex: .low, portionSize: 100),
        
        // Carbohidratos (IG variable)
        "french_fries": NutritionalInfo(calories: 365, carbohydrates: 63, proteins: 4, fats: 17, fiber: 4, sugars: 0.3, sodium: 246, glycemicIndex: .high, portionSize: 100),
        "pizza": NutritionalInfo(calories: 266, carbohydrates: 33, proteins: 11, fats: 10, fiber: 2.3, sugars: 3.6, sodium: 598, glycemicIndex: .medium, portionSize: 100),
        "fried_rice": NutritionalInfo(calories: 238, carbohydrates: 35, proteins: 6, fats: 8, fiber: 1.4, sugars: 2.1, sodium: 460, glycemicIndex: .high, portionSize: 100),
        "pasta": NutritionalInfo(calories: 220, carbohydrates: 44, proteins: 8, fats: 1.3, fiber: 2.5, sugars: 2.7, sodium: 6, glycemicIndex: .medium, portionSize: 100),
        
        // Ensaladas (Bajo IG)
        "caesar_salad": NutritionalInfo(calories: 113, carbohydrates: 5, proteins: 3, fats: 10, fiber: 2, sugars: 2, sodium: 305, glycemicIndex: .low, portionSize: 100),
        "greek_salad": NutritionalInfo(calories: 107, carbohydrates: 6, proteins: 3, fats: 9, fiber: 3, sugars: 4, sodium: 312, glycemicIndex: .low, portionSize: 100),
        
        // Mariscos (Bajo IG)
        "sushi": NutritionalInfo(calories: 156, carbohydrates: 24, proteins: 7, fats: 4, fiber: 3, sugars: 3.5, sodium: 428, glycemicIndex: .medium, portionSize: 100),
        "fish_and_chips": NutritionalInfo(calories: 265, carbohydrates: 17, proteins: 16, fats: 15, fiber: 1.4, sugars: 0.5, sodium: 435, glycemicIndex: .medium, portionSize: 100),
        
        // Desayunos (IG variable)
        "pancakes": NutritionalInfo(calories: 227, carbohydrates: 28, proteins: 6, fats: 10, fiber: 1.4, sugars: 6, sodium: 439, glycemicIndex: .high, portionSize: 100),
        "eggs_benedict": NutritionalInfo(calories: 230, carbohydrates: 8, proteins: 15, fats: 16, fiber: 0.5, sugars: 2, sodium: 920, glycemicIndex: .low, portionSize: 100),
    ]
    
    func getNutritionalInfo(for originalName: String, spanishName: String) -> NutritionalInfo {
        return food101Nutrition[originalName] ?? generateSmartDefaults(for: spanishName, originalName: originalName)
    }
    
    private func generateSmartDefaults(for spanishName: String, originalName: String) -> NutritionalInfo {
        let lower = originalName.lowercased()
        
        // Categorización inteligente para datos nutricionales
        if lower.contains("salad") || lower.contains("greens") {
            return NutritionalInfo(calories: 35, carbohydrates: 7, proteins: 2.5, fats: 0.3, fiber: 3, sugars: 4, sodium: 20, glycemicIndex: .low, portionSize: 100)
        } else if lower.contains("cake") || lower.contains("pie") || lower.contains("dessert") {
            return NutritionalInfo(calories: 350, carbohydrates: 45, proteins: 4, fats: 16, fiber: 2, sugars: 40, sodium: 300, glycemicIndex: .high, portionSize: 100)
        } else if lower.contains("chicken") || lower.contains("beef") || lower.contains("pork") || lower.contains("meat") {
            return NutritionalInfo(calories: 220, carbohydrates: 0, proteins: 25, fats: 12, fiber: 0, sugars: 0, sodium: 75, glycemicIndex: .low, portionSize: 100)
        } else if lower.contains("rice") || lower.contains("pasta") || lower.contains("bread") {
            return NutritionalInfo(calories: 200, carbohydrates: 40, proteins: 6, fats: 2, fiber: 2, sugars: 2, sodium: 10, glycemicIndex: .medium, portionSize: 100)
        } else if lower.contains("fish") || lower.contains("seafood") {
            return NutritionalInfo(calories: 180, carbohydrates: 0, proteins: 22, fats: 9, fiber: 0, sugars: 0, sodium: 80, glycemicIndex: .low, portionSize: 100)
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
            return "El modelo de IA Food101 no está disponible"
        case .imageProcessingFailed:
            return "Error procesando la imagen"
        case .noResults:
            return "La IA no pudo clasificar este alimento"
        }
    }
}