import Foundation

enum GlycemicIndex: String, Codable {
    case low // 0-55
    case medium // 56-69
    case high // 70+
    
    var range: ClosedRange<Int> {
        switch self {
        case .low: return 0...55
        case .medium: return 56...69
        case .high: return 70...100
        }
    }
}
