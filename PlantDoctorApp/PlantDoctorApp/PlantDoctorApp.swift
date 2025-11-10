//
//  PlantDoctorApp.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import SwiftUI
import FirebaseCore

@main
struct PlantDoctorApp: App {
    @StateObject private var notificationService = NotificationService.shared

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Check notification authorization status on app launch
                    Task {
                        await notificationService.checkAuthorizationStatus()
                    }
                }
        }
    }
}
