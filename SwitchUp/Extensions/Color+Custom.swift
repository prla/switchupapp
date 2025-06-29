import SwiftUI

extension Color {
    static let switchUpBlue = Color(red: 0, green: 0.035, blue: 1) // #0009FF equivalent
    static let userBubble = Color(red: 0.95, green: 0.95, blue: 1.0) // #F2F3FF
}

// For UIKit compatibility
extension UIColor {
    static let switchUpBlue = UIColor(red: 0/255, green: 9/255, blue: 255/255, alpha: 1)
    static let userBubble = UIColor(red: 242/255, green: 243/255, blue: 255/255, alpha: 1) // #F2F3FF
}
