//
//  PremiumService.swift
//  PlantDoctorApp
//
//  Created by Claude - PlantDoctor 2.0
//  Premium Subscription Management
//

import Foundation
import StoreKit

// MARK: - Premium Features
enum PremiumFeature: String {
    case aiCalendar = "AI Calendar"
    case unlimitedScans = "Unlimited Scans"
    case exportReports = "Export Reports"
    case offlineMode = "Offline Diagnosis"
    case prioritySupport = "Priority Support"
    case advancedAnalysis = "Advanced Environmental Analysis"

    var description: String {
        switch self {
        case .aiCalendar:
            return "Smart watering & fertilizing schedule based on AI analysis"
        case .unlimitedScans:
            return "Scan unlimited plants per day"
        case .exportReports:
            return "Export analysis reports as PDF/CSV"
        case .offlineMode:
            return "Diagnose plants without internet connection"
        case .prioritySupport:
            return "Get priority customer support"
        case .advancedAnalysis:
            return "Detailed environmental conditions analysis"
        }
    }

    var icon: String {
        switch self {
        case .aiCalendar: return "calendar.badge.clock"
        case .unlimitedScans: return "infinity"
        case .exportReports: return "square.and.arrow.up"
        case .offlineMode: return "wifi.slash"
        case .prioritySupport: return "headphones"
        case .advancedAnalysis: return "chart.xyaxis.line"
        }
    }
}

// MARK: - Premium Service
@MainActor
class PremiumService: ObservableObject {
    static let shared = PremiumService()

    @Published var isPremium: Bool = false
    @Published var subscriptionStatus: SubscriptionStatus = .free

    private let premiumKey = "isPremiumUser"
    private let subscriptionEndDateKey = "subscriptionEndDate"

    // Product IDs (configure these in App Store Connect)
    enum ProductID: String {
        case monthly = "com.plantdoctor.premium.monthly"
        case yearly = "com.plantdoctor.premium.yearly"
        case lifetime = "com.plantdoctor.premium.lifetime"

        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            case .lifetime: return "Lifetime"
            }
        }

        var price: String {
            switch self {
            case .monthly: return "$4.99/month"
            case .yearly: return "$39.99/year"
            case .lifetime: return "$99.99 once"
            }
        }

        var savingsText: String? {
            switch self {
            case .yearly: return "Save 33%"
            case .lifetime: return "Best Value"
            default: return nil
            }
        }
    }

    enum SubscriptionStatus {
        case free
        case premiumMonthly
        case premiumYearly
        case premiumLifetime

        var displayName: String {
            switch self {
            case .free: return "Free"
            case .premiumMonthly: return "Premium (Monthly)"
            case .premiumYearly: return "Premium (Yearly)"
            case .premiumLifetime: return "Premium (Lifetime)"
            }
        }
    }

    private init() {
        loadSubscriptionStatus()
    }

    // MARK: - Premium Access Check

    func hasAccess(to feature: PremiumFeature) -> Bool {
        // For development/testing, you can return true to test premium features
        // return true

        // In production, check actual premium status
        return isPremium
    }

    func checkFeatureAccess(for feature: PremiumFeature) -> (hasAccess: Bool, message: String?) {
        if hasAccess(to: feature) {
            return (true, nil)
        } else {
            return (false, "This is a premium feature. Upgrade to PlantDoctor Premium to unlock \(feature.rawValue).")
        }
    }

    // MARK: - Free Tier Limits

    private let maxFreeScansPerDay = 5
    private let freeScansKey = "freeScansCount"
    private let lastScanDateKey = "lastScanDate"

    func canPerformFreeScan() -> Bool {
        if isPremium {
            return true // No limit for premium users
        }

        let today = Calendar.current.startOfDay(for: Date())
        let lastScanDate = UserDefaults.standard.object(forKey: lastScanDateKey) as? Date ?? Date.distantPast
        let lastScanDay = Calendar.current.startOfDay(for: lastScanDate)

        // Reset counter if it's a new day
        if today > lastScanDay {
            UserDefaults.standard.set(0, forKey: freeScansKey)
            UserDefaults.standard.set(Date(), forKey: lastScanDateKey)
            return true
        }

        let scansToday = UserDefaults.standard.integer(forKey: freeScansKey)
        return scansToday < maxFreeScansPerDay
    }

    func incrementFreeScanCount() {
        if !isPremium {
            let scansToday = UserDefaults.standard.integer(forKey: freeScansKey)
            UserDefaults.standard.set(scansToday + 1, forKey: freeScansKey)
            UserDefaults.standard.set(Date(), forKey: lastScanDateKey)
        }
    }

    func remainingFreeScans() -> Int {
        if isPremium {
            return Int.max
        }

        let scansToday = UserDefaults.standard.integer(forKey: freeScansKey)
        return max(0, maxFreeScansPerDay - scansToday)
    }

    // MARK: - Subscription Management

    func loadSubscriptionStatus() {
        isPremium = UserDefaults.standard.bool(forKey: premiumKey)

        // Check if subscription has expired
        if let endDate = UserDefaults.standard.object(forKey: subscriptionEndDateKey) as? Date {
            if Date() > endDate {
                isPremium = false
                UserDefaults.standard.set(false, forKey: premiumKey)
            }
        }
    }

    func activatePremium(type: ProductID) {
        isPremium = true
        UserDefaults.standard.set(true, forKey: premiumKey)

        switch type {
        case .monthly:
            subscriptionStatus = .premiumMonthly
            let endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
            UserDefaults.standard.set(endDate, forKey: subscriptionEndDateKey)
        case .yearly:
            subscriptionStatus = .premiumYearly
            let endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
            UserDefaults.standard.set(endDate, forKey: subscriptionEndDateKey)
        case .lifetime:
            subscriptionStatus = .premiumLifetime
            UserDefaults.standard.removeObject(forKey: subscriptionEndDateKey)
        }
    }

    func deactivatePremium() {
        isPremium = false
        subscriptionStatus = .free
        UserDefaults.standard.set(false, forKey: premiumKey)
        UserDefaults.standard.removeObject(forKey: subscriptionEndDateKey)
    }

    // MARK: - In-App Purchase (Simplified)
    // Note: In production, implement full StoreKit 2 integration

    func purchase(productID: ProductID) async throws {
        // Simulate purchase for development
        // In production, implement actual StoreKit purchase flow

        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay

        activatePremium(type: productID)
    }

    func restorePurchases() async throws {
        // Simulate restore for development
        // In production, implement actual StoreKit restore flow

        try await Task.sleep(nanoseconds: 1_000_000_000)

        // For now, just reload status
        loadSubscriptionStatus()
    }

    // MARK: - Premium Benefits

    func getPremiumFeatures() -> [PremiumFeature] {
        return [
            .aiCalendar,
            .unlimitedScans,
            .advancedAnalysis,
            .offlineMode,
            .exportReports,
            .prioritySupport
        ]
    }

    func getSubscriptionPlans() -> [ProductID] {
        return [.monthly, .yearly, .lifetime]
    }
}
