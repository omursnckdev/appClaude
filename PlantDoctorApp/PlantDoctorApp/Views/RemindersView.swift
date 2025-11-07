//
//  RemindersView.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import SwiftUI

struct RemindersView: View {
    @StateObject private var viewModel = RemindersViewModel()
    @State private var showingAddReminder = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.reminders.isEmpty {
                    EmptyRemindersView()
                } else {
                    List {
                        ForEach(viewModel.reminders) { reminder in
                            ReminderRow(reminder: reminder, viewModel: viewModel)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deleteReminder(reminder)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("Care Reminders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddReminder = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView(viewModel: viewModel)
            }
        }
    }
}

struct ReminderRow: View {
    let reminder: CareReminder
    @ObservedObject var viewModel: RemindersViewModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.reminderType.icon)
                .font(.title2)
                .foregroundColor(reminder.isOverdue ? .red : .blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.plantName)
                    .font(.headline)

                Text(reminder.reminderType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    if reminder.isOverdue {
                        Text("Overdue by \(abs(reminder.daysUntilDue)) days")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if reminder.daysUntilDue == 0 {
                        Text("Due today")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("Due in \(reminder.daysUntilDue) days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: {
                viewModel.markCompleted(reminder)
            }) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .opacity(reminder.isEnabled ? 1.0 : 0.5)
    }
}

struct EmptyRemindersView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Reminders")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add care reminders for your plants")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct AddReminderView: View {
    @ObservedObject var viewModel: RemindersViewModel
    @Environment(\.dismiss) var dismiss

    @State private var plantName = ""
    @State private var reminderType: ReminderType = .watering
    @State private var frequency = 7
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Plant Information")) {
                    TextField("Plant Name", text: $plantName)
                }

                Section(header: Text("Reminder Details")) {
                    Picker("Type", selection: $reminderType) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }

                    Stepper("Every \(frequency) days", value: $frequency, in: 1...365)
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.addReminder(
                            plantName: plantName,
                            type: reminderType,
                            frequency: frequency,
                            notes: notes
                        )
                        dismiss()
                    }
                    .disabled(plantName.isEmpty)
                }
            }
        }
    }
}

@MainActor
class RemindersViewModel: ObservableObject {
    @Published var reminders: [CareReminder] = []

    init() {
        loadReminders()
    }

    func loadReminders() {
        reminders = PersistenceService.shared.getReminders()
            .sorted { r1, r2 in
                if r1.isOverdue != r2.isOverdue {
                    return r1.isOverdue
                }
                return r1.daysUntilDue < r2.daysUntilDue
            }
    }

    func addReminder(plantName: String, type: ReminderType, frequency: Int, notes: String) {
        let reminder = CareReminder(
            plantName: plantName,
            reminderType: type,
            frequency: frequency,
            notes: notes
        )
        PersistenceService.shared.saveReminder(reminder)
        loadReminders()
    }

    func markCompleted(_ reminder: CareReminder) {
        var updatedReminder = reminder
        updatedReminder.markCompleted()
        PersistenceService.shared.saveReminder(updatedReminder)
        loadReminders()
    }

    func deleteReminder(_ reminder: CareReminder) {
        PersistenceService.shared.deleteReminder(reminder)
        loadReminders()
    }
}
