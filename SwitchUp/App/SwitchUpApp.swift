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
    @State private var selectedTab = 0
    
    init() {
        // Customize the tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Remove default shadow and border
        appearance.shadowColor = nil
        appearance.shadowImage = UIImage()
        
        // Set the selection indicator color
        appearance.stackedLayoutAppearance.selected.iconColor = .label
        appearance.stackedLayoutAppearance.normal.iconColor = .secondaryLabel
        
        // Apply the appearance
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    ChatFlowView()
                        .environmentObject(chatViewModel)
                        .onAppear {
                            requestHealthAuthorizationAndFetchSummary()
                        }
                }
                .tag(0)
                .tabItem {
                    Label("", systemImage: "message.fill")
                        .accessibilityLabel("Coach")
                }

                NavigationStack {
                    InsightsView()
                }
                .tag(1)
                .tabItem {
                    Label("", systemImage: "chart.bar.fill")
                        .accessibilityLabel("Insights")
                }

                NavigationStack {
                    ProfileView()
                }
                .tag(2)
                .tabItem {
                    Label("", systemImage: "person.fill")
                        .accessibilityLabel("Profile")
                }
            }
            .accentColor(.primary)
        }
    }

    func requestHealthAuthorizationAndFetchSummary() {
        HealthService.shared.ensureAuthorization { granted, error in
            DispatchQueue.main.async {
                chatViewModel.startConversation("Hey there 👋 what brings you to SwitchUp today?")
            }
        }
    }
}
