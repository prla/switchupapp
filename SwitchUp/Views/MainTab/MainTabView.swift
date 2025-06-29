import SwiftUI

struct MainTabView: View {
    
    var body: some View {
        TabView {
            // Chat Tab
            NavigationStack {
                AICoachView()
            }
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
            
            // Insights Tab - Temporarily using a placeholder
            NavigationStack {
                Text("Insights coming soon")
                    .navigationTitle("Insights")
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar.fill")
            }
            
            // Profile Tab - Temporarily using a placeholder
            NavigationStack {
                Text("Profile coming soon")
                    .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
    }
}

#Preview {
    MainTabView()
}
