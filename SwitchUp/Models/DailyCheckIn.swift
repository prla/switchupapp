import Foundation

struct DailyCheckIn: Codable, Identifiable {
    let id: UUID
    let date: Date
    let answers: [CheckInAnswer]
}
