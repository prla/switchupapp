import SwiftUI

struct InsightsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Insights will be displayed here")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            }
            .navigationTitle("Insights")
        }
    }
}

#Preview {
    InsightsView()
}
