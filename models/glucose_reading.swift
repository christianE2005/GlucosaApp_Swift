import Foundation

struct GlucoseReading {
    let value: Int
    let timestamp: Date
    let notes: String
}

extension GlucoseReading {
    static let sampleReadings: [GlucoseReading] = [
        GlucoseReading(value: 95, timestamp: Date(), notes: "En ayunas"),
        GlucoseReading(value: 140, timestamp: Date().addingTimeInterval(7200), notes: "Después del almuerzo")
    ]
    
    var classification: String {
        switch value {
        case 0...70: return "Bajo"
        case 71...99: return "Normal"
        case 100...125: return "Prediabetes"
        default: return "Alto"
        }
    }
}
