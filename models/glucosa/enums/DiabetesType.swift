import Foundation

enum DiabetesType: String, Codable, CaseIterable, Identifiable {
    case type1 = "Tipo 1"
    case type2 = "Tipo 2"
    case gestational = "Gestacional"
    case prediabetes = "Prediabetes"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .type1:
            return "Diabetes Tipo 1 - El cuerpo no produce insulina"
        case .type2:
            return "Diabetes Tipo 2 - El cuerpo no usa la insulina correctamente"
        case .gestational:
            return "Diabetes Gestacional - Durante el embarazo"
        case .prediabetes:
            return "Prediabetes - Niveles de glucosa elevados"
        }
    }
}
