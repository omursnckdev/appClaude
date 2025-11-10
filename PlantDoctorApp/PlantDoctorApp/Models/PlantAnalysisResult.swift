//
//  PlantAnalysisResult.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import Foundation

// MARK: - Environmental Conditions
struct EnvironmentalConditions: Codable {
    let humidity: HumidityRecommendation
    let light: LightRecommendation
    let temperature: TemperatureRecommendation
    let soilMoisture: SoilMoistureRecommendation
    let airCirculation: String?

    struct HumidityRecommendation: Codable {
        let current: String  // e.g., "Low", "Moderate", "High"
        let ideal: String    // e.g., "40-60%"
        let adjustment: String // e.g., "Increase humidity by misting"
    }

    struct LightRecommendation: Codable {
        let current: String  // e.g., "Insufficient", "Good", "Excessive"
        let ideal: String    // e.g., "Bright indirect light"
        let adjustment: String // e.g., "Move closer to window"
        let hoursPerDay: String // e.g., "6-8 hours"
    }

    struct TemperatureRecommendation: Codable {
        let ideal: String    // e.g., "18-24°C (65-75°F)"
        let current: String  // e.g., "Likely adequate"
        let warnings: [String] // e.g., ["Avoid drafts", "Keep away from heaters"]
    }

    struct SoilMoistureRecommendation: Codable {
        let current: String  // e.g., "Appears dry", "Adequate", "Overwatered"
        let ideal: String    // e.g., "Moist but not soggy"
        let wateringFrequency: String // e.g., "Every 3-4 days"
        let tips: [String]   // e.g., ["Check top 2 inches of soil"]
    }
}

// MARK: - Plant Analysis Result
struct PlantAnalysisResult: Codable {
    let diagnosis: String
    let problems: [String]
    let treatment: String
    let isHealthy: Bool
    let confidenceLevel: String
    let plantIdentification: PlantIdentification?

    // PlantDoctor 2.0 - Enhanced environmental analysis
    let environmentalConditions: EnvironmentalConditions?
    let seasonalCare: SeasonalCare?
    let estimatedRecoveryTime: String?

    init(diagnosis: String,
         problems: [String],
         treatment: String,
         isHealthy: Bool,
         confidenceLevel: String,
         plantIdentification: PlantIdentification? = nil,
         environmentalConditions: EnvironmentalConditions? = nil,
         seasonalCare: SeasonalCare? = nil,
         estimatedRecoveryTime: String? = nil) {
        self.diagnosis = diagnosis
        self.problems = problems
        self.treatment = treatment
        self.isHealthy = isHealthy
        self.confidenceLevel = confidenceLevel
        self.plantIdentification = plantIdentification
        self.environmentalConditions = environmentalConditions
        self.seasonalCare = seasonalCare
        self.estimatedRecoveryTime = estimatedRecoveryTime
    }
}

// MARK: - Seasonal Care
struct SeasonalCare: Codable {
    let spring: String?
    let summer: String?
    let fall: String?
    let winter: String?
}
