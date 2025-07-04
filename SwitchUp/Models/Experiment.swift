import Foundation

var checkInRecords: [Date: CheckInStatus] = [:]

enum DifficultyLevel: String, Codable {
    case easy
    case medium
    case hard
}

struct Experiment: Identifiable, Codable {
    let id = UUID()
    let title: String
    let parts: [String]
    let startDate: Date
    let checkInDates: [Date]
    var checkInRecords: [String: CheckInStatus] = [:]
    var difficultyLevel: [String: DifficultyLevel] = [:]
}
