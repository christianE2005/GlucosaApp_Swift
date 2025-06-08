import Foundation

struct Meal: Identifiable, Codable {
    let id = UUID()
    var name: String
    var type: MealType
    var portions: [String]
    var timestamp: Date
    var glucoseReadingBefore: Double?
    var glucoseReadingAfter: Double?
    var totalCarbs: Double?
    var glucoseLevel: Double?
    var date: Date
    
    init(name: String, type: MealType = .breakfast, portions: [String] = [], timestamp: Date = Date(), glucoseReadingBefore: Double? = nil, glucoseReadingAfter: Double? = nil, totalCarbs: Double? = nil, glucoseLevel: Double? = nil, date: Date = Date()) {
        self.name = name
        self.type = type
        self.portions = portions
        self.timestamp = timestamp
        self.glucoseReadingBefore = glucoseReadingBefore
        self.glucoseReadingAfter = glucoseReadingAfter
        self.totalCarbs = totalCarbs
        self.glucoseLevel = glucoseLevel
        self.date = date
    }
}
