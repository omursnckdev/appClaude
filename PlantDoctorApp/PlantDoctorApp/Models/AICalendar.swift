//
//  AICalendar.swift
//  PlantDoctorApp
//
//  Created by Claude - PlantDoctor 2.0
//

import Foundation

// MARK: - AI Calendar Schedule
struct AICalendarSchedule: Codable, Identifiable {
    let id: String
    let plantRecordId: String
    let plantName: String
    let plantSpecies: String
    let schedules: [CareSchedule]
    let createdDate: Date
    let lastUpdated: Date

    init(id: String = UUID().uuidString,
         plantRecordId: String,
         plantName: String,
         plantSpecies: String,
         schedules: [CareSchedule],
         createdDate: Date = Date(),
         lastUpdated: Date = Date()) {
        self.id = id
        self.plantRecordId = plantRecordId
        self.plantName = plantName
        self.plantSpecies = plantSpecies
        self.schedules = schedules
        self.createdDate = createdDate
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Care Schedule Item
struct CareSchedule: Codable, Identifiable {
    let id: String
    let type: CareType
    let frequency: Frequency
    let nextDueDate: Date
    let timeOfDay: TimeOfDay?
    let amount: String?
    let notes: String?
    let aiGenerated: Bool

    enum CareType: String, Codable {
        case watering = "Watering"
        case fertilizing = "Fertilizing"
        case misting = "Misting"
        case pruning = "Pruning"
        case rotation = "Rotation"
        case inspection = "Inspection"

        var displayName: String {
            return self.rawValue
        }

        var icon: String {
            switch self {
            case .watering: return "drop.fill"
            case .fertilizing: return "leaf.fill"
            case .misting: return "cloud.rain.fill"
            case .pruning: return "scissors"
            case .rotation: return "arrow.triangle.2.circlepath"
            case .inspection: return "eye.fill"
            }
        }

        var color: String {
            switch self {
            case .watering: return "blue"
            case .fertilizing: return "green"
            case .misting: return "cyan"
            case .pruning: return "purple"
            case .rotation: return "orange"
            case .inspection: return "gray"
            }
        }
    }

    enum Frequency: Codable {
        case daily
        case everyNDays(Int)
        case weekly
        case biweekly
        case monthly
        case seasonal(Season)

        var description: String {
            switch self {
            case .daily: return "Daily"
            case .everyNDays(let days): return "Every \(days) days"
            case .weekly: return "Weekly"
            case .biweekly: return "Every 2 weeks"
            case .monthly: return "Monthly"
            case .seasonal(let season): return "Every \(season.rawValue)"
            }
        }

        var daysInterval: Int {
            switch self {
            case .daily: return 1
            case .everyNDays(let days): return days
            case .weekly: return 7
            case .biweekly: return 14
            case .monthly: return 30
            case .seasonal: return 90
            }
        }
    }

    enum TimeOfDay: String, Codable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case anytime = "Anytime"

        var icon: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .afternoon: return "sun.max.fill"
            case .evening: return "sunset.fill"
            case .anytime: return "clock.fill"
            }
        }
    }

    enum Season: String, Codable {
        case spring = "Spring"
        case summer = "Summer"
        case fall = "Fall"
        case winter = "Winter"
    }

    init(id: String = UUID().uuidString,
         type: CareType,
         frequency: Frequency,
         nextDueDate: Date,
         timeOfDay: TimeOfDay? = nil,
         amount: String? = nil,
         notes: String? = nil,
         aiGenerated: Bool = true) {
        self.id = id
        self.type = type
        self.frequency = frequency
        self.nextDueDate = nextDueDate
        self.timeOfDay = timeOfDay
        self.amount = amount
        self.notes = notes
        self.aiGenerated = aiGenerated
    }

    func isOverdue() -> Bool {
        return nextDueDate < Date()
    }

    func isDueToday() -> Bool {
        return Calendar.current.isDateInToday(nextDueDate)
    }

    func daysUntilDue() -> Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextDueDate).day ?? 0
        return days
    }

    func reschedule() -> CareSchedule {
        let calendar = Calendar.current
        let newDate = calendar.date(byAdding: .day, value: frequency.daysInterval, to: nextDueDate) ?? Date()

        return CareSchedule(
            id: id,
            type: type,
            frequency: frequency,
            nextDueDate: newDate,
            timeOfDay: timeOfDay,
            amount: amount,
            notes: notes,
            aiGenerated: aiGenerated
        )
    }
}

// MARK: - AI Calendar Event
struct AICalendarEvent: Identifiable {
    let id = UUID()
    let schedule: CareSchedule
    let plantName: String
    let plantSpecies: String
    let date: Date

    var isOverdue: Bool { schedule.isOverdue() }
    var isDueToday: Bool { schedule.isDueToday() }

    var urgencyLevel: UrgencyLevel {
        if isOverdue {
            return .overdue
        } else if isDueToday {
            return .today
        } else if schedule.daysUntilDue() <= 2 {
            return .soon
        } else {
            return .upcoming
        }
    }

    enum UrgencyLevel {
        case overdue
        case today
        case soon
        case upcoming

        var color: String {
            switch self {
            case .overdue: return "red"
            case .today: return "orange"
            case .soon: return "yellow"
            case .upcoming: return "green"
            }
        }

        var description: String {
            switch self {
            case .overdue: return "Overdue"
            case .today: return "Due Today"
            case .soon: return "Due Soon"
            case .upcoming: return "Upcoming"
            }
        }
    }
}
