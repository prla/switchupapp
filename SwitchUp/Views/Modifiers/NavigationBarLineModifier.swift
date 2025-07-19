import SwiftUI

struct NavigationBarLineModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            // Add the line at the very top
            Rectangle()
                .frame(height: 1 / UIScreen.main.scale)
                .foregroundColor(Color(.separator))
                .frame(maxWidth: .infinity)
                .offset(y: -1) // Slight offset to ensure it's visible
        }
    }
}

extension View {
    func navigationBarLine() -> some View {
        self.modifier(NavigationBarLineModifier())
    }
}
