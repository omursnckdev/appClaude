//
//  CareReminder.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import Foundation

enum ReminderType: String, Codable, CaseIterable {
    case watering = "Watering"
    case fertilizing = "Fertilizing"
    case pruning = "Pruning"
    case repotting = "Repotting"
    case pestControl = "Pest Control"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .watering: return "drop.fill"
        case .fertilizing: return "leaf.fill"
        case .pruning: return "scissors"
        case .repotting: return "tray.fill"
        case .pestControl: return "ant.fill"
        case .custom: return "bell.fill"
        }
    }
}

struct CareReminder: Codable, Identifiable {
    let id: UUID
    var plantName: String
    var reminderType: ReminderType
    var frequency: Int // days
    var lastCompleted: Date?
    var nextDue: Date
    var notes: String
    var isEnabled: Bool

    init(id: UUID = UUID(), plantName: String, reminderType: ReminderType, frequency: Int, lastCompleted: Date? = nil, notes: String = "", isEnabled: Bool = true) {
        self.id = id
        self.plantName = plantName
        self.reminderType = reminderType
        self.frequency = frequency
        self.lastCompleted = lastCompleted
        self.notes = notes
        self.isEnabled = isEnabled

        if let lastCompleted = lastCompleted {
            self.nextDue = Calendar.current.date(byAdding: .day, value: frequency, to: lastCompleted) ?? Date()
        } else {
            self.nextDue = Date()
        }
    }

    var isOverdue: Bool {
        nextDue < Date()
    }

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDue).day ?? 0
    }

    mutating func markCompleted() {
        lastCompleted = Date()
        nextDue = Calendar.current.date(byAdding: .day, value: frequency, to: Date()) ?? Date()
    }
}
