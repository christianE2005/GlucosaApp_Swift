import UIKit
import CoreML
import Vision
import Foundation

// MARK: - Modelos de datos
struct FoodAnalysisResult {
    let foodName: String
    let confidence: Float
    let nutritionalInfo: NutritionalInfo
    let healthInsights: [HealthInsight]
    let timestamp: Date
    
    init(foodName: String, confidence: Float, nutritionalInfo: NutritionalInfo, healthInsights: [HealthInsight] = []) {
        self.foodName = foodName
        self.confidence = confidence
        self.nutritionalInfo = nutritionalInfo
        self.healthInsights = healthInsights
        self.timestamp = Date()
    }
}

struct NutritionalInfo {
    let calories: Double
    let carbohydrates: Double
    let proteins: Double
    let fats: Double
    let fiber: Double
    let sugars: Double
    let sodium: Double
    let glycemicIndex: GlycemicIndex
    let portionSize: Double // en gramos
    
    var glycemicLoad: Double {
        return (carbohydrates * Double(glycemicIndex.range.lowerBound)) / 100.0
    }
    
    var carbsPerGlucoseImpact: String {
        switch glycemicLoad {
        case 0...10: return "Bajo impacto"
        case 11...19: return "Impacto moderado"
        default: return "Alto impacto"
        }
    }
}

struct HealthInsight {
    let title: String
    let description: String
    let category: InsightCategory
    let severity: InsightSeverity
    
    enum InsightCategory {
        case glucose, nutrition, portion, timing
        
        var icon: String {
            switch self {
            case .glucose: return "drop.fill"
            case .nutrition: return "leaf.fill"
            case .portion: return "scalemass.fill"
            case .timing: return "clock.fill"
            }
        }
    }
    
    enum InsightSeverity {
        case info, warning, critical
        
        var color: String {
            switch self {
            case .info: return "blue"
            case .warning: return "orange"
            case .critical: return "red"
            }
        }
    }
}

// MARK: - Servicio de Clasificación
class FoodClassificationService {
    private var model: VNCoreMLModel?
    private let nutritionalDatabase = NutritionalDatabase()
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        guard let modelURL = Bundle.main.url(forResource: "FoodClassifier", withExtension: "mlmodel") else {
            print("❌ No se encontró el modelo FoodClassifier.mlmodel")
            return
        }
        
        do {
            let model = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            self.model = model
            print("✅ Modelo CoreML cargado exitosamente")
        } catch {
            print("❌ Error cargando modelo: \(error)")
        }
    }
    
    func classifyFood(image: UIImage) async throws -> FoodAnalysisResult {
        guard let model = model else {
            throw ClassificationError.modelNotLoaded
        }
        
        guard let cgImage = image.cgImage else {
            throw ClassificationError.imageProcessingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    continuation.resume(throwing: ClassificationError.noResults)
                    return
                }
                
                let foodName = self.cleanFoodName(topResult.identifier)
                let confidence = topResult.confidence
                
                // Obtener información nutricional
                let nutritionalInfo = self.nutritionalDatabase.getNutritionalInfo(for: foodName)
                
                // Generar insights de salud
                let insights = self.generateHealthInsights(
                    foodName: foodName,
                    nutritionalInfo: nutritionalInfo,
                    confidence: confidence
                )
                
                let result = FoodAnalysisResult(
                    foodName: foodName,
                    confidence: confidence,
                    nutritionalInfo: nutritionalInfo,
                    healthInsights: insights
                )
                
                continuation.resume(returning: result)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func cleanFoodName(_ rawName: String) -> String {
        // Limpiar el nombre del food101 dataset
        return rawName
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    private func generateHealthInsights(foodName: String, nutritionalInfo: NutritionalInfo, confidence: Float) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Insight sobre confianza
        if confidence < 0.7 {
            insights.append(HealthInsight(
                title: "Verificar Identificación",
                description: "La identificación del alimento tiene baja confianza (\(Int(confidence * 100))%). Considera verificar manualmente.",
                category: .nutrition,
                severity: .warning
            ))
        }
        
        // Insight sobre índice glucémico
        switch nutritionalInfo.glycemicIndex {
        case .high:
            insights.append(HealthInsight(
                title: "Alto Índice Glucémico",
                description: "Este alimento puede elevar rápidamente los niveles de glucosa. Considera combinarlo con proteínas o fibra.",
                category: .glucose,
                severity: .warning
            ))
        case .low:
            insights.append(HealthInsight(
                title: "Excelente Opción",
                description: "Bajo índice glucémico. Ideal para mantener niveles estables de glucosa.",
                category: .glucose,
                severity: .info
            ))
        case .medium:
            insights.append(HealthInsight(
                title: "Moderado Impacto",
                description: "Índice glucémico moderado. Controla la porción para mejores resultados.",
                category: .glucose,
                severity: .info
            ))
        }
        
        // Insight sobre carbohidratos
        if nutritionalInfo.carbohydrates > 50 {
            insights.append(HealthInsight(
                title: "Alto en Carbohidratos",
                description: "Contiene \(Int(nutritionalInfo.carbohydrates))g de carbohidratos por porción. Ajusta tu medicación si es necesario.",
                category: .nutrition,
                severity: .warning
            ))
        }
        
        // Insight sobre fibra
        if nutritionalInfo.fiber > 5 {
            insights.append(HealthInsight(
                title: "Rico en Fibra",
                description: "Excelente fuente de fibra (\(Int(nutritionalInfo.fiber))g). Ayuda a controlar la glucosa.",
                category: .nutrition,
                severity: .info
            ))
        }
        
        return insights
    }
}

// MARK: - Database nutricional
class NutritionalDatabase {
    private let nutritionalData: [String: NutritionalInfo] = [
        // Frutas
        "Apple Pie": NutritionalInfo(calories: 237, carbohydrates: 34, proteins: 2, fats: 11, fiber: 2, sugars: 19, sodium: 240, glycemicIndex: .medium, portionSize: 100),
        "Banana": NutritionalInfo(calories: 89, carbohydrates: 23, proteins: 1, fats: 0.3, fiber: 3, sugars: 17, sodium: 1, glycemicIndex: .medium, portionSize: 100),
        "Orange": NutritionalInfo(calories: 47, carbohydrates: 12, proteins: 1, fats: 0.1, fiber: 2.4, sugars: 9, sodium: 0, glycemicIndex: .low, portionSize: 100),
        
        // Proteínas
        "Steak": NutritionalInfo(calories: 271, carbohydrates: 0, proteins: 26, fats: 17, fiber: 0, sugars: 0, sodium: 59, glycemicIndex: .low, portionSize: 100),
        "Chicken Wings": NutritionalInfo(calories: 203, carbohydrates: 0, proteins: 30, fats: 8, fiber: 0, sugars: 0, sodium: 82, glycemicIndex: .low, portionSize: 100),
        "Fish And Chips": NutritionalInfo(calories: 265, carbohydrates: 17, proteins: 16, fats: 15, fiber: 1.4, sugars: 0.5, sodium: 435, glycemicIndex: .high, portionSize: 100),
        
        // Carbohidratos
        "Bread Pudding": NutritionalInfo(calories: 153, carbohydrates: 22, proteins: 4, fats: 5, fiber: 1, sugars: 10, sodium: 153, glycemicIndex: .high, portionSize: 100),
        "French Fries": NutritionalInfo(calories: 365, carbohydrates: 63, proteins: 4, fats: 17, fiber: 4, sugars: 0.3, sodium: 246, glycemicIndex: .high, portionSize: 100),
        "Pizza": NutritionalInfo(calories: 266, carbohydrates: 33, proteins: 11, fats: 10, fiber: 2.3, sugars: 3.6, sodium: 598, glycemicIndex: .medium, portionSize: 100),
        
        // Verduras
        "Caesar Salad": NutritionalInfo(calories: 113, carbohydrates: 5, proteins: 3, fats: 10, fiber: 2, sugars: 2, sodium: 305, glycemicIndex: .low, portionSize: 100),
        "Spinach": NutritionalInfo(calories: 23, carbohydrates: 3.6, proteins: 3, fats: 0.4, fiber: 2.2, sugars: 0.4, sodium: 79, glycemicIndex: .low, portionSize: 100),
        
        // Postres
        "Chocolate Cake": NutritionalInfo(calories: 371, carbohydrates: 50, proteins: 5, fats: 16, fiber: 3, sugars: 36, sodium: 469, glycemicIndex: .high, portionSize: 100),
        "Ice Cream": NutritionalInfo(calories: 207, carbohydrates: 24, proteins: 4, fats: 11, fiber: 0.7, sugars: 21, sodium: 80, glycemicIndex: .high, portionSize: 100)
    ]
    
    func getNutritionalInfo(for foodName: String) -> NutritionalInfo {
        return nutritionalData[foodName] ?? getDefaultNutritionalInfo(for: foodName)
    }
    
    private func getDefaultNutritionalInfo(for foodName: String) -> NutritionalInfo {
        // Valores por defecto basados en el tipo de alimento
        let lowercased = foodName.lowercased()
        
        if lowercased.contains("fruit") || lowercased.contains("apple") || lowercased.contains("berry") {
            return NutritionalInfo(calories: 60, carbohydrates: 15, proteins: 0.5, fats: 0.2, fiber: 3, sugars: 12, sodium: 1, glycemicIndex: .medium, portionSize: 100)
        } else if lowercased.contains("vegetable") || lowercased.contains("salad") || lowercased.contains("greens") {
            return NutritionalInfo(calories: 25, carbohydrates: 5, proteins: 2, fats: 0.2, fiber: 2.5, sugars: 2, sodium: 10, glycemicIndex: .low, portionSize: 100)
        } else if lowercased.contains("meat") || lowercased.contains("chicken") || lowercased.contains("fish") {
            return NutritionalInfo(calories: 200, carbohydrates: 0, proteins: 25, fats: 10, fiber: 0, sugars: 0, sodium: 75, glycemicIndex: .low, portionSize: 100)
        } else {
            return NutritionalInfo(calories: 150, carbohydrates: 20, proteins: 5, fats: 5, fiber: 2, sugars: 5, sodium: 150, glycemicIndex: .medium, portionSize: 100)
        }
    }
}

// MARK: - Errores
enum ClassificationError: Error {
    case modelNotLoaded
    case imageProcessingFailed
    case noResults
    
    var localizedDescription: String {
        switch self {
        case .modelNotLoaded:
            return "El modelo de clasificación no está disponible"
        case .imageProcessingFailed:
            return "Error procesando la imagen"
        case .noResults:
            return "No se pudieron obtener resultados"
        }
    }
}