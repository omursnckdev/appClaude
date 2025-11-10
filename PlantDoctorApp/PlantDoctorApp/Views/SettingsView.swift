//
//  SettingsView.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Language")) {
                    Picker("App Language", selection: $viewModel.selectedLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                            }
                            .tag(language)
                        }
                    }
                    .onChange(of: viewModel.selectedLanguage) { newValue in
                        viewModel.updateLanguage(newValue)
                    }
                }

                Section(header: Text("AI Provider")) {
                    Picker("AI Service", selection: $viewModel.selectedAIProvider) {
                        Text("Claude (Anthropic)").tag(AIProvider.claude)
                        Text("GPT-4 Vision (OpenAI)").tag(AIProvider.openai)
                        Text("Gemini (Google)").tag(AIProvider.gemini)
                    }
                    .pickerStyle(.inline)

                    Text("The AI provider will be used for plant analysis and identification")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Data & Storage")) {
                    HStack {
                        Text("Cache Size")
                        Spacer()
                        Text(viewModel.cacheSize)
                            .foregroundColor(.secondary)
                    }

                    Button(action: {
                        viewModel.clearCache()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Cache")
                        }
                        .foregroundColor(.red)
                    }
                }

                Section(header: Text("Notifications")) {
                    Toggle("Care Reminders", isOn: $viewModel.notificationsEnabled)
                        .onChange(of: viewModel.notificationsEnabled) { newValue in
                            Task {
                                await viewModel.toggleNotifications(newValue)
                            }
                        }

                    Toggle("Community Updates", isOn: $viewModel.communityNotificationsEnabled)
                        .onChange(of: viewModel.communityNotificationsEnabled) { newValue in
                            viewModel.toggleCommunityNotifications(newValue)
                        }

                    Text("Get reminded about watering, fertilizing, and other care tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: AboutView()) {
                        Text("About Plant Doctor")
                    }

                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                    }

                    NavigationLink(destination: TermsOfServiceView()) {
                        Text("Terms of Service")
                    }
                }

                Section {
                    Button(action: {
                        viewModel.shareApp()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Plant Doctor")
                        }
                    }

                    Button(action: {
                        viewModel.rateApp()
                    }) {
                        HStack {
                            Image(systemName: "star")
                            Text("Rate the App")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Notifications", isPresented: $viewModel.showNotificationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.notificationAlertMessage)
            }
        }
    }
}

enum AIProvider: String, CaseIterable {
    case claude = "Claude"
    case openai = "OpenAI"
    case gemini = "Gemini"
}

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var selectedLanguage: AppLanguage
    @Published var selectedAIProvider: AIProvider = .claude
    @Published var notificationsEnabled = false
    @Published var communityNotificationsEnabled = false
    @Published var cacheSize = "Calculating..."
    @Published var showNotificationAlert = false
    @Published var notificationAlertMessage = ""

    private let notificationService = NotificationService.shared
    private let userDefaults = UserDefaults.standard
    private let notificationSettingsKey = "notificationsEnabled"
    private let communityNotificationSettingsKey = "communityNotificationsEnabled"

    init() {
        self.selectedLanguage = LocalizationService.shared.getLanguage()
        // Load notification settings from UserDefaults
        self.notificationsEnabled = userDefaults.bool(forKey: notificationSettingsKey)
        self.communityNotificationsEnabled = userDefaults.bool(forKey: communityNotificationSettingsKey)
        calculateCacheSize()
        checkNotificationStatus()
    }

    func checkNotificationStatus() {
        Task {
            await notificationService.checkAuthorizationStatus()
            // Update the toggle based on actual authorization status
            notificationsEnabled = notificationService.isAuthorized
        }
    }

    func toggleNotifications(_ enabled: Bool) async {
        if enabled {
            // Request notification permission
            do {
                let granted = try await notificationService.requestAuthorization()
                if granted {
                    notificationsEnabled = true
                    userDefaults.set(true, forKey: notificationSettingsKey)
                    notificationAlertMessage = "Notifications enabled! You'll receive reminders for plant care tasks."
                } else {
                    notificationsEnabled = false
                    userDefaults.set(false, forKey: notificationSettingsKey)
                    notificationAlertMessage = "Notification permission denied. Please enable it in Settings."
                }
                showNotificationAlert = true
            } catch {
                notificationsEnabled = false
                userDefaults.set(false, forKey: notificationSettingsKey)
                notificationAlertMessage = "Failed to request notification permission: \(error.localizedDescription)"
                showNotificationAlert = true
            }
        } else {
            // Disable notifications
            notificationsEnabled = false
            userDefaults.set(false, forKey: notificationSettingsKey)
        }
    }

    func toggleCommunityNotifications(_ enabled: Bool) {
        communityNotificationsEnabled = enabled
        userDefaults.set(enabled, forKey: communityNotificationSettingsKey)
    }

    func updateLanguage(_ language: AppLanguage) {
        LocalizationService.shared.setLanguage(language)
    }

    func clearCache() {
        // Clear UserDefaults cache
        UserDefaults.standard.removeObject(forKey: "offlineCache")
        calculateCacheSize()
    }

    func calculateCacheSize() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        if let size = try? FileManager.default.allocatedSizeOfDirectory(at: documentsPath) {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useMB, .useKB]
            formatter.countStyle = .file
            cacheSize = formatter.string(fromByteCount: Int64(size))
        } else {
            cacheSize = "0 MB"
        }
    }

    func shareApp() {
        let text = "Check out Plant Doctor - diagnose your plant's health with AI! 🌱"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    func rateApp() {
        // Open App Store rating page
        if let url = URL(string: "https://apps.apple.com/app/idXXXXXXXXXX?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

extension FileManager {
    func allocatedSizeOfDirectory(at url: URL) throws -> Int {
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]

        var size = 0
        let enumerator = self.enumerator(at: url, includingPropertiesForKeys: Array(resourceKeys))!

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)

            if resourceValues.isRegularFile ?? false {
                size += resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0
            }
        }

        return size
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)

                Text("Plant Doctor")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)

                Text("Your AI-Powered Plant Health Assistant")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)

                Divider()
                    .padding(.vertical)

                VStack(alignment: .leading, spacing: 15) {
                    Text("Features")
                        .font(.headline)

                    FeatureRow(icon: "camera.fill", title: "AI Plant Analysis", description: "Identify diseases and health issues")
                    FeatureRow(icon: "leaf.fill", title: "Plant Identification", description: "Recognize plant species instantly")
                    FeatureRow(icon: "bell.fill", title: "Care Reminders", description: "Never forget to water your plants")
                    FeatureRow(icon: "clock.arrow.circlepath", title: "History Tracking", description: "Keep records of all analyses")
                    FeatureRow(icon: "person.3", title: "Community", description: "Share and learn from others")
                    FeatureRow(icon: "arrow.down.doc", title: "Export Reports", description: "Save and share analysis reports")
                }

                Divider()
                    .padding(.vertical)

                Text("Made with 🌱 for plant lovers everywhere")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Last updated: \(Date().formatted(date: .long, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                Text("Data Collection")
                    .font(.headline)
                Text("Plant Doctor collects plant images and analysis results to provide its services. All data is stored locally on your device unless you choose to share with the community.")

                Text("AI Processing")
                    .font(.headline)
                Text("Images are sent to AI providers (Claude, OpenAI, or Gemini) for analysis. These providers may have their own privacy policies.")

                Text("Community Features")
                    .font(.headline)
                Text("When you share to the community, your posts are stored in our Firebase database and visible to other users.")

                Text("Your Rights")
                    .font(.headline)
                Text("You can delete your data anytime through the History page. You control what you share with the community.")
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Last updated: \(Date().formatted(date: .long, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                Text("Acceptance of Terms")
                    .font(.headline)
                Text("By using Plant Doctor, you agree to these terms of service.")

                Text("Service Description")
                    .font(.headline)
                Text("Plant Doctor provides AI-powered plant health analysis for informational purposes only. It is not a substitute for professional botanical advice.")

                Text("User Responsibilities")
                    .font(.headline)
                Text("You are responsible for the content you share in the community. Do not share inappropriate, offensive, or copyrighted content.")

                Text("Disclaimer")
                    .font(.headline)
                Text("Plant analysis results are AI-generated and may not be 100% accurate. Always consult with a professional for serious plant health issues.")
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}
