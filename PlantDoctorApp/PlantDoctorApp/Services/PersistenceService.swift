//
//  PersistenceService.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import Foundation
import UIKit

class PersistenceService {
    static let shared = PersistenceService()

    private let historyKey = "plantAnalysisHistory"
    private let remindersKey = "careReminders"
    private let languageKey = "appLanguage"
    private let cacheKey = "offlineCache"
    private let imagesDirectory: URL

    private init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        imagesDirectory = paths[0].appendingPathComponent("PlantImages", isDirectory: true)

        // Create images directory if it doesn't exist
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }

    // MARK: - History Management

    func saveRecord(_ record: PlantRecord) {
        var history = getHistory()
        history.insert(record, at: 0) // Insert at beginning
        saveHistory(history)
    }

    func getHistory() -> [PlantRecord] {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let records = try? JSONDecoder().decode([PlantRecord].self, from: data) else {
            return []
        }
        return records
    }

    func deleteRecord(_ record: PlantRecord) {
        var history = getHistory()
        history.removeAll { $0.id == record.id }
        saveHistory(history)

        // Delete associated image
        if !record.imageName.isEmpty {
            deleteImage(named: record.imageName)
        }
    }

    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
        // Clear all images
        try? FileManager.default.removeItem(at: imagesDirectory)
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }

    private func saveHistory(_ history: [PlantRecord]) {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    // MARK: - Image Management

    func saveImage(_ image: UIImage, withName name: String) -> String {
        let imageUrl = imagesDirectory.appendingPathComponent(name)

        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: imageUrl)
        }

        return name
    }

    func loadImage(named name: String) -> UIImage? {
        let imageUrl = imagesDirectory.appendingPathComponent(name)
        guard let data = try? Data(contentsOf: imageUrl) else { return nil }
        return UIImage(data: data)
    }

    func deleteImage(named name: String) {
        let imageUrl = imagesDirectory.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: imageUrl)
    }

    // MARK: - Care Reminders

    func saveReminder(_ reminder: CareReminder) {
        var reminders = getReminders()
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
        } else {
            reminders.append(reminder)
        }
        saveReminders(reminders)
    }

    func getReminders() -> [CareReminder] {
        guard let data = UserDefaults.standard.data(forKey: remindersKey),
              let reminders = try? JSONDecoder().decode([CareReminder].self, from: data) else {
            return []
        }
        return reminders
    }

    func deleteReminder(_ reminder: CareReminder) {
        var reminders = getReminders()
        reminders.removeAll { $0.id == reminder.id }
        saveReminders(reminders)
    }

    private func saveReminders(_ reminders: [CareReminder]) {
        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: remindersKey)
        }
    }

    // MARK: - Language Preference

    func saveLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
    }

    func getLanguage() -> AppLanguage {
        guard let languageString = UserDefaults.standard.string(forKey: languageKey),
              let language = AppLanguage(rawValue: languageString) else {
            return .english
        }
        return language
    }

    // MARK: - Offline Cache

    func cacheAnalysisResult(imageId: String, result: PlantAnalysisResult) {
        var cache = getCache()
        cache[imageId] = result
        saveCache(cache)
    }

    func getCachedResult(for imageId: String) -> PlantAnalysisResult? {
        let cache = getCache()
        return cache[imageId]
    }

    private func getCache() -> [String: PlantAnalysisResult] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cache = try? JSONDecoder().decode([String: PlantAnalysisResult].self, from: data) else {
            return [:]
        }
        return cache
    }

    private func saveCache(_ cache: [String: PlantAnalysisResult]) {
        if let encoded = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
}
