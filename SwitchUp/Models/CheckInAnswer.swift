import Foundation

struct CheckInAnswer: Codable {
    let question: String
    let answer: String
    let coachFeedback: String?
}
