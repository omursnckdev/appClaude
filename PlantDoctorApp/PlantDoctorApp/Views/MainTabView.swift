//
//  MainTabView.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Analyze", systemImage: "camera.fill")
                }
                .tag(0)

            // PlantDoctor 2.0 - AI Calendar (Premium)
            AICalendarView()
                .tabItem {
                    Label("AI Calendar", systemImage: "calendar.badge.clock")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(2)

            RemindersView()
                .tabItem {
                    Label("Reminders", systemImage: "bell.fill")
                }
                .tag(3)

            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }
                .tag(4)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(5)
        }
        .accentColor(.green)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
