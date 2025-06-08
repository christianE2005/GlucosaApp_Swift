import Foundation

struct GlucoseReading: Identifiable, Codable, Comparable, Hashable {
    var id = UUID()
    var value: Int
    var timestamp: Date
    var notes: String
    
    init(value: Int, timestamp: Date, notes: String) {
        self.value = value
        self.timestamp = timestamp
        self.notes = notes
    }
    
    var classification: String {
        switch value {
        case 0...70: return "Bajo"
        case 71...99: return "Normal"
        case 100...125: return "Prediabetes"
        default: return "Alto"
        }
    }
    
    static func < (lhs: GlucoseReading, rhs: GlucoseReading) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
    
    static let sampleReadings: [GlucoseReading] = [
        GlucoseReading(value: 95, timestamp: Date(), notes: "En ayunas"),
        GlucoseReading(value: 140, timestamp: Date().addingTimeInterval(7200), notes: "Después del almuerzo")
    ]
}
