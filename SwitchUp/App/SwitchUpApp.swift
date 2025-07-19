//
//  SwitchUpApp.swift
//  SwitchUp
//
//  Created by Paulo André on 28.06.25.
//

import SwiftUI

@main
struct SwitchUpApp: App {
    @StateObject private var chatViewModel = ChatViewModel()

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    ChatFlowView()
                        .environmentObject(chatViewModel)
                        .onAppear {
                            requestHealthAuthorizationAndFetchSummary()
                        }
                        .navigationTitle("Coach")
                }
                .tabItem {
                    Label("Coach", systemImage: "message.fill")
                }

                NavigationStack {
                    InsightsView()
                        .navigationTitle("Insights")
                }
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }

                NavigationStack {
                    ProfileView()
                        .navigationTitle("Profile")
                }
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
            }
        }
    }

    func requestHealthAuthorizationAndFetchSummary() {
        HealthService.shared.ensureAuthorization { granted, error in
            if granted {
                HealthService.shared.fetchBasicHealthSummary { summary in
                    print("Health summary:", summary)
                    DispatchQueue.main.async {
                        chatViewModel.startConversation("Coach: Hi! \(summary) Let's start by clarifying your main goal.")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    chatViewModel.startConversation("Coach: Hi! Let's start by clarifying your main goal.")
                }
            }
        }
    }
}
