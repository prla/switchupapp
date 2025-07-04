import Foundation

struct Experiment: Identifiable, Codable {
    let id = UUID()
    let title: String
    let parts: [String]
    let startDate: Date
    let checkInDates: [Date]
}