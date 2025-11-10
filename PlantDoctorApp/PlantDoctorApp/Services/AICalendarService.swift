//
//  AICalendarService.swift
//  PlantDoctorApp
//
//  Created by Claude - PlantDoctor 2.0
//  Premium Feature: AI-powered smart scheduling
//

import Foundation
import UIKit

@MainActor
class AICalendarService {
    static let shared = AICalendarService()

    private let persistenceKey = "AICalendarSchedules"
    private let userDefaults = UserDefaults.standard
    private let notificationService = NotificationService.shared

    private init() {}

    // MARK: - Generate AI Schedule

    /// Generate intelligent care schedule based on plant analysis
    func generateSchedule(
        from analysis: PlantAnalysisResult,
        plantRecord: PlantRecord
    ) -> AICalendarSchedule {
        var schedules: [CareSchedule] = []

        // 1. Generate watering schedule based on plant needs and soil moisture
        let wateringSchedule = generateWateringSchedule(from: analysis)
        schedules.append(wateringSchedule)

        // 2. Generate fertilizing schedule
        let fertilizingSchedule = generateFertilizingSchedule(from: analysis)
        schedules.append(fertilizingSchedule)

        // 3. Generate misting schedule if humidity is low
        if let mistingSchedule = generateMistingSchedule(from: analysis) {
            schedules.append(mistingSchedule)
        }

        // 4. Generate inspection schedule
        let inspectionSchedule = generateInspectionSchedule(isHealthy: analysis.isHealthy)
        schedules.append(inspectionSchedule)

        // 5. Generate rotation schedule for proper light exposure
        if let rotationSchedule = generateRotationSchedule(from: analysis) {
            schedules.append(rotationSchedule)
        }

        // 6. Generate pruning schedule if needed
        if let pruningSchedule = generatePruningSchedule(from: analysis) {
            schedules.append(pruningSchedule)
        }

        return AICalendarSchedule(
            plantRecordId: plantRecord.id,
            plantName: analysis.plantIdentification?.commonName ?? "Plant",
            plantSpecies: analysis.plantIdentification?.species ?? "Unknown",
            schedules: schedules
        )
    }

    // MARK: - Schedule Generators

    private func generateWateringSchedule(from analysis: PlantAnalysisResult) -> CareSchedule {
        var frequencyDays = 3 // Default

        // Parse watering frequency from environmental conditions
        if let soilMoisture = analysis.environmentalConditions?.soilMoisture {
            let frequency = soilMoisture.wateringFrequency.lowercased()

            if frequency.contains("daily") {
                frequencyDays = 1
            } else if frequency.contains("2-3") || frequency.contains("every 2") {
                frequencyDays = 2
            } else if frequency.contains("3-4") || frequency.contains("every 3") {
                frequencyDays = 3
            } else if frequency.contains("4-5") || frequency.contains("every 4") {
                frequencyDays = 4
            } else if frequency.contains("5-7") || frequency.contains("weekly") {
                frequencyDays = 7
            } else if frequency.contains("10") || frequency.contains("10-14") {
                frequencyDays = 10
            }

            // Adjust based on current moisture level
            if soilMoisture.current.lowercased().contains("dry") {
                frequencyDays = max(1, frequencyDays - 1)
            } else if soilMoisture.current.lowercased().contains("overwater") {
                frequencyDays = min(14, frequencyDays + 3)
            }
        }

        // Get watering needs from plant identification
        if let wateringNeeds = analysis.plantIdentification?.wateringNeeds.lowercased() {
            if wateringNeeds.contains("frequent") || wateringNeeds.contains("high") {
                frequencyDays = min(frequencyDays, 2)
            } else if wateringNeeds.contains("moderate") {
                frequencyDays = 3
            } else if wateringNeeds.contains("low") || wateringNeeds.contains("infrequent") {
                frequencyDays = max(frequencyDays, 7)
            }
        }

        let nextDate = Calendar.current.date(byAdding: .day, value: frequencyDays, to: Date()) ?? Date()

        return CareSchedule(
            type: .watering,
            frequency: .everyNDays(frequencyDays),
            nextDueDate: nextDate,
            timeOfDay: .morning,
            amount: "Water until soil is moist but not soggy",
            notes: analysis.environmentalConditions?.soilMoisture.tips.first,
            aiGenerated: true
        )
    }

    private func generateFertilizingSchedule(from analysis: PlantAnalysisResult) -> CareSchedule {
        var frequencyDays = 30 // Default monthly

        // Check for nutrient deficiencies
        let hasNutrientIssues = analysis.problems.contains { problem in
            problem.lowercased().contains("nutrient") ||
            problem.lowercased().contains("deficiency") ||
            problem.lowercased().contains("nitrogen") ||
            problem.lowercased().contains("iron") ||
            problem.lowercased().contains("yellowing")
        }

        if hasNutrientIssues {
            frequencyDays = 14 // Biweekly if nutrient deficient
        }

        // Adjust based on care level
        if let careLevel = analysis.plantIdentification?.careLevel.lowercased() {
            if careLevel.contains("difficult") {
                frequencyDays = 21 // Every 3 weeks for demanding plants
            }
        }

        let nextDate = Calendar.current.date(byAdding: .day, value: frequencyDays, to: Date()) ?? Date()

        return CareSchedule(
            type: .fertilizing,
            frequency: .everyNDays(frequencyDays),
            nextDueDate: nextDate,
            timeOfDay: .morning,
            amount: "Balanced liquid fertilizer at half strength",
            notes: hasNutrientIssues ? "Nutrient deficiency detected - fertilize regularly" : "Regular feeding schedule",
            aiGenerated: true
        )
    }

    private func generateMistingSchedule(from analysis: PlantAnalysisResult) -> CareSchedule? {
        guard let humidity = analysis.environmentalConditions?.humidity else {
            return nil
        }

        // Only create misting schedule if humidity is low
        if humidity.current.lowercased().contains("low") {
            let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

            return CareSchedule(
                type: .misting,
                frequency: .daily,
                nextDueDate: nextDate,
                timeOfDay: .morning,
                notes: humidity.adjustment,
                aiGenerated: true
            )
        }

        return nil
    }

    private func generateInspectionSchedule(isHealthy: Bool) -> CareSchedule {
        let frequencyDays = isHealthy ? 7 : 3 // More frequent if unhealthy
        let nextDate = Calendar.current.date(byAdding: .day, value: frequencyDays, to: Date()) ?? Date()

        return CareSchedule(
            type: .inspection,
            frequency: isHealthy ? .weekly : .everyNDays(3),
            nextDueDate: nextDate,
            timeOfDay: .anytime,
            notes: isHealthy ? "Regular health check" : "Monitor recovery progress closely",
            aiGenerated: true
        )
    }

    private func generateRotationSchedule(from analysis: PlantAnalysisResult) -> CareSchedule? {
        guard let light = analysis.environmentalConditions?.light else {
            return nil
        }

        // Rotation needed if light is uneven or plant needs specific light
        let needsRotation = light.current.lowercased().contains("insufficient") ||
                           light.adjustment.lowercased().contains("rotate")

        if needsRotation {
            let nextDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

            return CareSchedule(
                type: .rotation,
                frequency: .weekly,
                nextDueDate: nextDate,
                timeOfDay: .anytime,
                notes: "Rotate 90° for even light exposure",
                aiGenerated: true
            )
        }

        return nil
    }

    private func generatePruningSchedule(from analysis: PlantAnalysisResult) -> CareSchedule? {
        // Check if pruning is mentioned in treatment
        let needsPruning = analysis.treatment.lowercased().contains("prune") ||
                          analysis.treatment.lowercased().contains("trim") ||
                          analysis.treatment.lowercased().contains("remove dead")

        if needsPruning {
            let nextDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

            return CareSchedule(
                type: .pruning,
                frequency: .monthly,
                nextDueDate: nextDate,
                timeOfDay: .afternoon,
                notes: "Remove dead or damaged leaves",
                aiGenerated: true
            )
        }

        return nil
    }

    // MARK: - Persistence

    func saveSchedule(_ schedule: AICalendarSchedule) {
        var schedules = getAllSchedules()

        // Remove old schedule for same plant if exists
        schedules.removeAll { $0.plantRecordId == schedule.plantRecordId }

        schedules.append(schedule)

        if let encoded = try? JSONEncoder().encode(schedules) {
            userDefaults.set(encoded, forKey: persistenceKey)
        }

        // Schedule notifications for all care tasks
        Task {
            await scheduleNotificationsForSchedule(schedule)
        }
    }

    private func scheduleNotificationsForSchedule(_ schedule: AICalendarSchedule) async {
        for careSchedule in schedule.schedules {
            do {
                try await notificationService.scheduleCareReminder(
                    id: careSchedule.id,
                    plantName: schedule.plantName,
                    reminderType: careSchedule.type.displayName,
                    dueDate: careSchedule.nextDueDate,
                    notes: careSchedule.notes
                )
            } catch {
                print("Failed to schedule notification for \(careSchedule.type.displayName): \(error)")
            }
        }
    }

    func getAllSchedules() -> [AICalendarSchedule] {
        guard let data = userDefaults.data(forKey: persistenceKey),
              let schedules = try? JSONDecoder().decode([AICalendarSchedule].self, from: data) else {
            return []
        }
        return schedules
    }

    func getSchedule(forPlantId plantId: String) -> AICalendarSchedule? {
        return getAllSchedules().first { $0.plantRecordId == plantId }
    }

    func deleteSchedule(id: String) {
        // Get the schedule before deleting to cancel its notifications
        if let schedule = getAllSchedules().first(where: { $0.id == id }) {
            // Cancel all notifications for this schedule
            for careSchedule in schedule.schedules {
                notificationService.cancelNotification(withId: careSchedule.id)
            }
        }

        var schedules = getAllSchedules()
        schedules.removeAll { $0.id == id }

        if let encoded = try? JSONEncoder().encode(schedules) {
            userDefaults.set(encoded, forKey: persistenceKey)
        }
    }

    func updateSchedule(_ schedule: AICalendarSchedule) {
        var schedules = getAllSchedules()
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            var updated = schedule
            schedules[index] = AICalendarSchedule(
                id: updated.id,
                plantRecordId: updated.plantRecordId,
                plantName: updated.plantName,
                plantSpecies: updated.plantSpecies,
                schedules: updated.schedules,
                createdDate: updated.createdDate,
                lastUpdated: Date()
            )

            if let encoded = try? JSONEncoder().encode(schedules) {
                userDefaults.set(encoded, forKey: persistenceKey)
            }
        }
    }

    // MARK: - Events Management

    func getUpcomingEvents(daysAhead: Int = 14) -> [AICalendarEvent] {
        let schedules = getAllSchedules()
        var events: [AICalendarEvent] = []

        let endDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: Date()) ?? Date()

        for schedule in schedules {
            for careSchedule in schedule.schedules {
                if careSchedule.nextDueDate <= endDate {
                    let event = AICalendarEvent(
                        schedule: careSchedule,
                        plantName: schedule.plantName,
                        plantSpecies: schedule.plantSpecies,
                        date: careSchedule.nextDueDate
                    )
                    events.append(event)
                }
            }
        }

        // Sort by date
        return events.sorted { $0.date < $1.date }
    }

    func getOverdueEvents() -> [AICalendarEvent] {
        return getUpcomingEvents(daysAhead: 0).filter { $0.isOverdue }
    }

    func getTodayEvents() -> [AICalendarEvent] {
        return getUpcomingEvents(daysAhead: 0).filter { $0.isDueToday }
    }

    func completeEvent(_ event: AICalendarEvent) {
        if let schedule = getSchedule(forPlantId: event.plantName) {
            var updatedSchedules = schedule.schedules
            if let index = updatedSchedules.firstIndex(where: { $0.id == event.schedule.id }) {
                let rescheduledCareSchedule = event.schedule.reschedule()
                updatedSchedules[index] = rescheduledCareSchedule

                let updatedSchedule = AICalendarSchedule(
                    id: schedule.id,
                    plantRecordId: schedule.plantRecordId,
                    plantName: schedule.plantName,
                    plantSpecies: schedule.plantSpecies,
                    schedules: updatedSchedules,
                    createdDate: schedule.createdDate,
                    lastUpdated: Date()
                )

                updateSchedule(updatedSchedule)

                // Reschedule notification for the updated care task
                Task {
                    do {
                        try await notificationService.updateNotification(
                            id: rescheduledCareSchedule.id,
                            plantName: schedule.plantName,
                            reminderType: rescheduledCareSchedule.type.displayName,
                            newDueDate: rescheduledCareSchedule.nextDueDate,
                            notes: rescheduledCareSchedule.notes
                        )
                    } catch {
                        print("Failed to reschedule notification: \(error)")
                    }
                }
            }
        }
    }
}
