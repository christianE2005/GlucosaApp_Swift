import Foundation

// Add the missing struct definition
struct GlucoseReading: Codable {
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

extension GlucoseReading: Comparable {
    static func < (lhs: GlucoseReading, rhs: GlucoseReading) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
}

extension GlucoseReading: Hashable {
    func hash(into hasher: inout Hasher) {
        // Remove 'id' - it doesn't exist in your struct
        hasher.combine(value)
        hasher.combine(timestamp)
        hasher.combine(notes)
    }
}

extension GlucoseReading: CustomStringConvertible {
    var description: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let formattedDate = dateFormatter.string(from: timestamp)
        
        // Fix: notes is a String, not optional
        return "Glucose Reading: \(value) mg/dL on \(formattedDate) - \(classification)\(notes.isEmpty ? "" : " (\(notes))")"
    }
}

extension GlucoseReading {
    static func fromJSON(_ json: String) -> GlucoseReading? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(GlucoseReading.self, from: data)
    }
    
    func toJSON() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
