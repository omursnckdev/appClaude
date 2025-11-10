//
//  AICalendarView.swift
//  PlantDoctorApp
//
//  Created by Claude - PlantDoctor 2.0
//  Premium Feature: AI Calendar
//

import SwiftUI

struct AICalendarView: View {
    @StateObject private var viewModel = AICalendarViewModel()
    @ObservedObject private var premiumService = PremiumService.shared
    @State private var showingPremiumSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                if !premiumService.isPremium {
                    // Premium upsell
                    premiumUpsellView
                } else {
                    // AI Calendar content
                    calendarContentView
                }
            }
            .navigationTitle("🗓️ AI Calendar")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumUpgradeView()
            }
        }
    }

    // MARK: - Premium Upsell
    private var premiumUpsellView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("AI Calendar")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Smart watering & fertilizing schedule")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "brain.head.profile", text: "AI-powered scheduling based on your plant analysis")
                FeatureRow(icon: "bell.badge.fill", text: "Smart reminders for watering, fertilizing & more")
                FeatureRow(icon: "calendar.badge.plus", text: "Automatic schedule updates as your plant recovers")
                FeatureRow(icon: "leaf.fill", text: "Personalized care for each plant species")
            }
            .padding()

            Button(action: {
                showingPremiumSheet = true
            }) {
                Text("Unlock AI Calendar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(15)
            }
            .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Calendar Content
    private var calendarContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                HStack(spacing: 15) {
                    SummaryCard(
                        title: "Overdue",
                        count: viewModel.overdueCount,
                        icon: "exclamationmark.triangle.fill",
                        color: .red
                    )

                    SummaryCard(
                        title: "Today",
                        count: viewModel.todayCount,
                        icon: "clock.fill",
                        color: .orange
                    )

                    SummaryCard(
                        title: "Upcoming",
                        count: viewModel.upcomingCount,
                        icon: "calendar",
                        color: .green
                    )
                }
                .padding(.horizontal)

                // Events list
                if viewModel.events.isEmpty {
                    emptyStateView
                } else {
                    eventsListView
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Scheduled Events")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Analyze a plant to generate an AI schedule")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private var eventsListView: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(viewModel.groupedEvents.keys.sorted(), id: \.self) { date in
                if let events = viewModel.groupedEvents[date] {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(formatDate(date))
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)

                        ForEach(events) { event in
                            AICalendarEventCard(event: event) {
                                viewModel.completeEvent(event)
                            }
                        }
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Event Card
struct AICalendarEventCard: View {
    let event: AICalendarEvent
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: event.schedule.type.icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.2))
                .cornerRadius(10)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(event.schedule.type.rawValue)
                    .font(.headline)

                Text(event.plantName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let notes = event.schedule.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(event.schedule.frequency.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Complete button
            Button(action: onComplete) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var iconColor: Color {
        switch event.urgencyLevel {
        case .overdue: return .red
        case .today: return .orange
        case .soon: return .yellow
        case .upcoming: return .green
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 25)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - ViewModel
@MainActor
class AICalendarViewModel: ObservableObject {
    @Published var events: [AICalendarEvent] = []
    @Published var groupedEvents: [Date: [AICalendarEvent]] = [:]
    @Published var overdueCount = 0
    @Published var todayCount = 0
    @Published var upcomingCount = 0

    init() {
        loadEvents()
    }

    func loadEvents() {
        events = AICalendarService.shared.getUpcomingEvents(daysAhead: 14)
        groupEventsByDate()
        updateCounts()
    }

    func refresh() async {
        loadEvents()
    }

    func completeEvent(_ event: AICalendarEvent) {
        AICalendarService.shared.completeEvent(event)
        loadEvents()
    }

    private func groupEventsByDate() {
        let calendar = Calendar.current
        groupedEvents = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.date)
        }
    }

    private func updateCounts() {
        overdueCount = events.filter { $0.isOverdue }.count
        todayCount = events.filter { $0.isDueToday }.count
        upcomingCount = events.filter { !$0.isOverdue && !$0.isDueToday }.count
    }
}

// MARK: - Premium Upgrade View
struct PremiumUpgradeView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var premiumService = PremiumService.shared
    @State private var selectedPlan: PremiumService.ProductID = .yearly
    @State private var isPurchasing = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)

                        Text("PlantDoctor Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Unlock all premium features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Features
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(premiumService.getPremiumFeatures(), id: \.self.rawValue) { feature in
                            HStack(spacing: 15) {
                                Image(systemName: feature.icon)
                                    .foregroundColor(.green)
                                    .frame(width: 30)

                                VStack(alignment: .leading) {
                                    Text(feature.rawValue)
                                        .font(.headline)
                                    Text(feature.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)

                    // Plans
                    VStack(spacing: 12) {
                        ForEach(premiumService.getSubscriptionPlans(), id: \.self.rawValue) { plan in
                            PlanCard(
                                plan: plan,
                                isSelected: selectedPlan == plan,
                                onSelect: { selectedPlan = plan }
                            )
                        }
                    }

                    // Purchase button
                    Button(action: {
                        purchasePremium()
                    }) {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Start Premium")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(15)
                    .disabled(isPurchasing)

                    // Restore purchases
                    Button("Restore Purchases") {
                        restorePurchases()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
    }

    private func purchasePremium() {
        isPurchasing = true
        Task {
            do {
                try await premiumService.purchase(productID: selectedPlan)
                dismiss()
            } catch {
                print("Purchase failed: \(error)")
            }
            isPurchasing = false
        }
    }

    private func restorePurchases() {
        Task {
            try? await premiumService.restorePurchases()
        }
    }
}

struct PlanCard: View {
    let plan: PremiumService.ProductID
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.displayName)
                            .font(.headline)

                        if let savings = plan.savingsText {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }

                    Text(plan.price)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.system(size: 24))
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
