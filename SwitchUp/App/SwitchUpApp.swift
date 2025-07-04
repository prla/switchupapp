//
//  SwitchUpApp.swift
//  SwitchUp
//
//  Created by Paulo André on 28.06.25.
//

import SwiftUI

@main
struct SwitchUpApp: App {
    @StateObject private var userProfile = UserProfile()
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(userProfile)
        }
    }
}
