import SwiftUI

struct InsightsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTitleView()
                
                VStack {
                    Text("Insights will be displayed here")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    InsightsView()
}
