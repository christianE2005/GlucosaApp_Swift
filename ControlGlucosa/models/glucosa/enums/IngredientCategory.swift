import Foundation
import SwiftUI

enum IngredientCategory: String, Codable, CaseIterable, Identifiable {
    case vegetable
    case fruit
    case grain
    case protein
    case dairy
    case fat
    case other

    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .vegetable: return "Vegetales"
        case .fruit: return "Frutas"
        case .grain: return "Cereales"
        case .protein: return "Proteínas"
        case .dairy: return "Lácteos"
        case .fat: return "Grasas"
        case .other: return "Otros"
        }
    }
}