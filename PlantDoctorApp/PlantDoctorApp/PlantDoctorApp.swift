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

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
