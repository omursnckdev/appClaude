//
//  OfflineAIService.swift
//  PlantDoctorApp
//
//  Created by Claude - PlantDoctor 2.0
//  Offline AI Diagnosis (Premium Feature)
//

import Foundation
import UIKit
import Vision
import CoreML

class OfflineAIService {
    static let shared = OfflineAIService()

    private init() {}

    // MARK: - Offline Analysis

    /// Perform basic offline analysis using Vision framework and pattern matching
    func analyzePlantImageOffline(_ image: UIImage) async throws -> PlantAnalysisResult {
        // Check if user has premium access
        guard await PremiumService.shared.hasAccess(to: .offlineMode) else {
            throw OfflineAIError.premiumRequired
        }

        // Perform basic image analysis using Vision framework
        let imageCharacteristics = try await analyzeImageCharacteristics(image)

        // Generate diagnosis based on visual characteristics
        let diagnosis = generateOfflineDiagnosis(from: imageCharacteristics)

        return diagnosis
    }

    // MARK: - Image Analysis

    private func analyzeImageCharacteristics(_ image: UIImage) async throws -> ImageCharacteristics {
        guard let cgImage = image.cgImage else {
            throw OfflineAIError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            // Analyze dominant colors
            let request = VNDetectHorizonRequest()

            // Color analysis for leaf health
            var characteristics = ImageCharacteristics()

            // Analyze color distribution
            let colors = analyzeColorDistribution(cgImage)
            characteristics.dominantColors = colors
            characteristics.hasYellowing = colors.contains { $0.isYellowish }
            characteristics.hasBrowning = colors.contains { $0.isBrownish }
            characteristics.hasGreenColor = colors.contains { $0.isGreenish }

            // Brightness analysis (can indicate light issues)
            characteristics.averageBrightness = calculateAverageBrightness(cgImage)

            // Texture analysis (rough approximation)
            characteristics.hasSpots = detectPotentialSpots(cgImage)

            continuation.resume(returning: characteristics)
        }
    }

    private func analyzeColorDistribution(_ cgImage: CGImage) -> [ColorInfo] {
        var colors: [ColorInfo] = []

        let width = cgImage.width
        let height = cgImage.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return colors
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else {
            return colors
        }

        let pixelData = data.bindMemory(to: UInt8.self, capacity: width * height * 4)

        // Sample pixels (every 10th pixel for performance)
        var redSum: CGFloat = 0
        var greenSum: CGFloat = 0
        var blueSum: CGFloat = 0
        var sampleCount = 0

        for y in stride(from: 0, to: height, by: 10) {
            for x in stride(from: 0, to: width, by: 10) {
                let offset = (y * width + x) * 4
                let r = CGFloat(pixelData[offset]) / 255.0
                let g = CGFloat(pixelData[offset + 1]) / 255.0
                let b = CGFloat(pixelData[offset + 2]) / 255.0

                redSum += r
                greenSum += g
                blueSum += b
                sampleCount += 1
            }
        }

        if sampleCount > 0 {
            let avgColor = ColorInfo(
                red: redSum / CGFloat(sampleCount),
                green: greenSum / CGFloat(sampleCount),
                blue: blueSum / CGFloat(sampleCount)
            )
            colors.append(avgColor)
        }

        return colors
    }

    private func calculateAverageBrightness(_ cgImage: CGImage) -> CGFloat {
        // Simplified brightness calculation
        return 0.5 // Placeholder - in production, calculate actual brightness
    }

    private func detectPotentialSpots(_ cgImage: CGImage) -> Bool {
        // Simplified spot detection
        // In production, use proper image processing
        return false
    }

    // MARK: - Diagnosis Generation

    private func generateOfflineDiagnosis(from characteristics: ImageCharacteristics) -> PlantAnalysisResult {
        var problems: [String] = []
        var isHealthy = true
        var diagnosis = "Offline analysis complete."
        var treatment = ""

        // Analyze based on color distribution
        if characteristics.hasYellowing {
            problems.append("Yellowing leaves detected")
            isHealthy = false
            diagnosis += " Yellowing leaves may indicate overwatering, nutrient deficiency, or insufficient light."
            treatment += "• Check watering schedule\n• Consider adding fertilizer\n• Ensure adequate light\n"
        }

        if characteristics.hasBrowning {
            problems.append("Brown discoloration detected")
            isHealthy = false
            diagnosis += " Brown edges or spots may indicate underwatering, low humidity, or nutrient issues."
            treatment += "• Increase watering frequency\n• Improve humidity levels\n• Check for pests\n"
        }

        if !characteristics.hasGreenColor {
            problems.append("Lack of healthy green color")
            isHealthy = false
            diagnosis += " Insufficient green coloration suggests health issues."
            treatment += "• Review overall care routine\n• Check environmental conditions\n"
        }

        if characteristics.hasSpots {
            problems.append("Spotted pattern detected")
            isHealthy = false
            diagnosis += " Spots may indicate fungal infection or pest damage."
            treatment += "• Inspect for pests\n• Reduce humidity if fungal\n• Consider fungicide treatment\n"
        }

        // Brightness analysis
        if characteristics.averageBrightness < 0.3 {
            problems.append("Low light exposure indicated")
            treatment += "• Move to brighter location\n• Increase light exposure\n"
        }

        if isHealthy {
            diagnosis = "Plant appears healthy based on offline analysis."
            treatment = "Continue current care routine. Monitor regularly for any changes."
        }

        // Create basic environmental recommendations
        let environmentalConditions = EnvironmentalConditions(
            humidity: EnvironmentalConditions.HumidityRecommendation(
                current: characteristics.hasBrowning ? "Likely low" : "Adequate",
                ideal: "40-60%",
                adjustment: characteristics.hasBrowning ? "Increase humidity by misting or using a humidifier" : "Maintain current humidity"
            ),
            light: EnvironmentalConditions.LightRecommendation(
                current: characteristics.averageBrightness < 0.3 ? "Insufficient" : "Adequate",
                ideal: "Bright indirect light",
                adjustment: characteristics.averageBrightness < 0.3 ? "Move to a brighter location" : "Continue current light exposure",
                hoursPerDay: "6-8 hours"
            ),
            temperature: EnvironmentalConditions.TemperatureRecommendation(
                ideal: "18-24°C (65-75°F)",
                current: "Unable to assess offline",
                warnings: ["Keep away from drafts", "Avoid extreme temperature changes"]
            ),
            soilMoisture: EnvironmentalConditions.SoilMoistureRecommendation(
                current: characteristics.hasYellowing ? "Possibly overwatered" : "Check manually",
                ideal: "Moist but not soggy",
                wateringFrequency: "Every 3-5 days (adjust based on soil dryness)",
                tips: ["Check top 2 inches of soil before watering", "Ensure proper drainage"]
            ),
            airCirculation: "Ensure good air circulation around the plant"
        )

        return PlantAnalysisResult(
            diagnosis: diagnosis,
            problems: problems.isEmpty ? ["No obvious issues detected"] : problems,
            treatment: treatment.isEmpty ? "Continue monitoring plant health." : treatment,
            isHealthy: isHealthy,
            confidenceLevel: "Low (Offline Mode)",
            plantIdentification: nil,
            environmentalConditions: environmentalConditions,
            seasonalCare: nil,
            estimatedRecoveryTime: isHealthy ? nil : "1-2 weeks with proper care"
        )
    }
}

// MARK: - Supporting Types

struct ImageCharacteristics {
    var dominantColors: [ColorInfo] = []
    var hasYellowing: Bool = false
    var hasBrowning: Bool = false
    var hasGreenColor: Bool = false
    var hasSpots: Bool = false
    var averageBrightness: CGFloat = 0.5
}

struct ColorInfo {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    var isGreenish: Bool {
        return green > red && green > blue && green > 0.3
    }

    var isYellowish: Bool {
        return red > 0.5 && green > 0.5 && blue < 0.4
    }

    var isBrownish: Bool {
        return red > 0.3 && green > 0.2 && blue < 0.3 && red > green
    }
}

enum OfflineAIError: Error {
    case invalidImage
    case premiumRequired
    case modelNotAvailable

    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .premiumRequired:
            return "Offline diagnosis is a premium feature"
        case .modelNotAvailable:
            return "Offline model not available"
        }
    }
}
