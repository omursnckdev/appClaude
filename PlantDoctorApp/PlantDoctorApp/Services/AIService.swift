//
//  AIService.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import Foundation
import UIKit

enum AIServiceError: Error {
    case invalidImage
    case networkError
    case invalidResponse
    case apiKeyMissing
}

class AIService {
    private let apiKey: String
    private let endpoint = "https://api.anthropic.com/v1/messages"

    init() {
        // Load API key from Config.plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["CLAUDE_API_KEY"] as? String else {
            self.apiKey = ""
            print("Warning: Claude API key not found in Config.plist")
            return
        }
        self.apiKey = key
    }

    func analyzePlantImage(_ image: UIImage, language: AppLanguage = .english) async throws -> PlantAnalysisResult {
        guard !apiKey.isEmpty else {
            throw AIServiceError.apiKeyMissing
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AIServiceError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()

        // Construct the request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let requestBody: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": """
                            You are an expert plant pathologist and horticulturist. Analyze this plant image comprehensively.

                            🌿 PlantDoctor 2.0 - Enhanced Analysis
                            Please provide a complete assessment including identification, health diagnosis, AND environmental conditions.

                            Respond in the following JSON format:
                            {
                                "plantIdentification": {
                                    "species": "Plant species name",
                                    "commonName": "Common name",
                                    "scientificName": "Scientific name",
                                    "family": "Plant family",
                                    "description": "Brief description of the plant",
                                    "careLevel": "Easy/Moderate/Difficult",
                                    "wateringNeeds": "Description of watering requirements",
                                    "sunlightNeeds": "Description of sunlight requirements",
                                    "confidenceLevel": "High/Medium/Low"
                                },
                                "isHealthy": true/false,
                                "diagnosis": "Detailed diagnosis of the plant's health",
                                "problems": ["specific issue 1", "specific issue 2"],
                                "treatment": "Step-by-step treatment recommendations",
                                "confidenceLevel": "High/Medium/Low",
                                "estimatedRecoveryTime": "e.g., 1-2 weeks with proper care",
                                "environmentalConditions": {
                                    "humidity": {
                                        "current": "Low/Moderate/High based on leaf appearance",
                                        "ideal": "e.g., 40-60%",
                                        "adjustment": "Specific advice to adjust humidity"
                                    },
                                    "light": {
                                        "current": "Insufficient/Good/Excessive based on leaf color and growth",
                                        "ideal": "e.g., Bright indirect light",
                                        "adjustment": "How to adjust light conditions",
                                        "hoursPerDay": "e.g., 6-8 hours"
                                    },
                                    "temperature": {
                                        "ideal": "e.g., 18-24°C (65-75°F)",
                                        "current": "Assessment based on visible stress",
                                        "warnings": ["warning 1", "warning 2"]
                                    },
                                    "soilMoisture": {
                                        "current": "Dry/Adequate/Overwatered based on leaf turgor",
                                        "ideal": "e.g., Moist but not soggy",
                                        "wateringFrequency": "e.g., Every 3-4 days",
                                        "tips": ["tip 1", "tip 2"]
                                    },
                                    "airCirculation": "Recommendations for air flow"
                                },
                                "seasonalCare": {
                                    "spring": "Spring care tips",
                                    "summer": "Summer care tips",
                                    "fall": "Fall care tips",
                                    "winter": "Winter care tips"
                                }
                            }

                            Analysis Guidelines:
                            1. IDENTIFICATION: Identify the plant species with confidence level
                            2. HEALTH ASSESSMENT:
                               - Leaf discoloration (yellowing, browning, spots, edges)
                               - Wilting, drooping, or loss of turgor
                               - Pests or insects visible
                               - Fungal infections or mold
                               - Nutrient deficiencies (N, P, K, Fe, Mg)
                               - Root problems (if visible)
                               - Environmental stress indicators

                            3. ENVIRONMENTAL ANALYSIS (NEW in 2.0):
                               - HUMIDITY: Assess from leaf appearance (curling, brown edges = low humidity)
                               - LIGHT: Assess from leaf color (pale/leggy = insufficient, burnt = excessive)
                               - TEMPERATURE: Look for heat/cold stress signs
                               - SOIL MOISTURE: Assess from leaf turgor and appearance
                               - Provide specific, actionable adjustments

                            4. SEASONAL CARE: Provide season-specific care instructions

                            Respond in \(language.displayName) language.
                            Be specific, scientific, and provide actionable advice.
                            """
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.networkError
        }

        // Parse Claude API response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AIServiceError.invalidResponse
        }

        // Extract JSON from the response text
        let jsonText = extractJSON(from: text)
        guard let jsonData = jsonText.data(using: .utf8),
              let analysisJson = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw AIServiceError.invalidResponse
        }

        // Parse plant identification
        var plantIdentification: PlantIdentification?
        if let identificationJson = analysisJson["plantIdentification"] as? [String: Any] {
            plantIdentification = PlantIdentification(
                species: identificationJson["species"] as? String ?? "Unknown",
                commonName: identificationJson["commonName"] as? String ?? "Unknown",
                scientificName: identificationJson["scientificName"] as? String ?? "Unknown",
                family: identificationJson["family"] as? String ?? "Unknown",
                description: identificationJson["description"] as? String ?? "",
                careLevel: identificationJson["careLevel"] as? String ?? "Moderate",
                wateringNeeds: identificationJson["wateringNeeds"] as? String ?? "",
                sunlightNeeds: identificationJson["sunlightNeeds"] as? String ?? "",
                confidenceLevel: identificationJson["confidenceLevel"] as? String ?? "Medium"
            )
        }

        // Parse environmental conditions (PlantDoctor 2.0)
        var environmentalConditions: EnvironmentalConditions?
        if let envJson = analysisJson["environmentalConditions"] as? [String: Any] {
            let humidity = parseHumidity(from: envJson["humidity"] as? [String: Any])
            let light = parseLight(from: envJson["light"] as? [String: Any])
            let temperature = parseTemperature(from: envJson["temperature"] as? [String: Any])
            let soilMoisture = parseSoilMoisture(from: envJson["soilMoisture"] as? [String: Any])
            let airCirculation = envJson["airCirculation"] as? String

            environmentalConditions = EnvironmentalConditions(
                humidity: humidity,
                light: light,
                temperature: temperature,
                soilMoisture: soilMoisture,
                airCirculation: airCirculation
            )
        }

        // Parse seasonal care (PlantDoctor 2.0)
        var seasonalCare: SeasonalCare?
        if let seasonalJson = analysisJson["seasonalCare"] as? [String: Any] {
            seasonalCare = SeasonalCare(
                spring: seasonalJson["spring"] as? String,
                summer: seasonalJson["summer"] as? String,
                fall: seasonalJson["fall"] as? String,
                winter: seasonalJson["winter"] as? String
            )
        }

        // Parse the analysis result
        let isHealthy = analysisJson["isHealthy"] as? Bool ?? false
        let diagnosis = analysisJson["diagnosis"] as? String ?? "Unable to determine"
        let problems = analysisJson["problems"] as? [String] ?? []
        let treatment = analysisJson["treatment"] as? String ?? "Consult a plant specialist"
        let confidenceLevel = analysisJson["confidenceLevel"] as? String ?? "Medium"
        let estimatedRecoveryTime = analysisJson["estimatedRecoveryTime"] as? String

        return PlantAnalysisResult(
            diagnosis: diagnosis,
            problems: problems,
            treatment: treatment,
            isHealthy: isHealthy,
            confidenceLevel: confidenceLevel,
            plantIdentification: plantIdentification,
            environmentalConditions: environmentalConditions,
            seasonalCare: seasonalCare,
            estimatedRecoveryTime: estimatedRecoveryTime
        )
    }

    // MARK: - Environmental Parsing Helpers (PlantDoctor 2.0)

    private func parseHumidity(from json: [String: Any]?) -> EnvironmentalConditions.HumidityRecommendation {
        guard let json = json else {
            return EnvironmentalConditions.HumidityRecommendation(
                current: "Unknown",
                ideal: "40-60%",
                adjustment: "Monitor humidity levels"
            )
        }
        return EnvironmentalConditions.HumidityRecommendation(
            current: json["current"] as? String ?? "Unknown",
            ideal: json["ideal"] as? String ?? "40-60%",
            adjustment: json["adjustment"] as? String ?? "Monitor humidity levels"
        )
    }

    private func parseLight(from json: [String: Any]?) -> EnvironmentalConditions.LightRecommendation {
        guard let json = json else {
            return EnvironmentalConditions.LightRecommendation(
                current: "Unknown",
                ideal: "Bright indirect light",
                adjustment: "Ensure adequate lighting",
                hoursPerDay: "6-8 hours"
            )
        }
        return EnvironmentalConditions.LightRecommendation(
            current: json["current"] as? String ?? "Unknown",
            ideal: json["ideal"] as? String ?? "Bright indirect light",
            adjustment: json["adjustment"] as? String ?? "Ensure adequate lighting",
            hoursPerDay: json["hoursPerDay"] as? String ?? "6-8 hours"
        )
    }

    private func parseTemperature(from json: [String: Any]?) -> EnvironmentalConditions.TemperatureRecommendation {
        guard let json = json else {
            return EnvironmentalConditions.TemperatureRecommendation(
                ideal: "18-24°C (65-75°F)",
                current: "Unknown",
                warnings: []
            )
        }
        return EnvironmentalConditions.TemperatureRecommendation(
            ideal: json["ideal"] as? String ?? "18-24°C (65-75°F)",
            current: json["current"] as? String ?? "Unknown",
            warnings: json["warnings"] as? [String] ?? []
        )
    }

    private func parseSoilMoisture(from json: [String: Any]?) -> EnvironmentalConditions.SoilMoistureRecommendation {
        guard let json = json else {
            return EnvironmentalConditions.SoilMoistureRecommendation(
                current: "Unknown",
                ideal: "Moist but not soggy",
                wateringFrequency: "Every 3-5 days",
                tips: ["Check soil before watering"]
            )
        }
        return EnvironmentalConditions.SoilMoistureRecommendation(
            current: json["current"] as? String ?? "Unknown",
            ideal: json["ideal"] as? String ?? "Moist but not soggy",
            wateringFrequency: json["wateringFrequency"] as? String ?? "Every 3-5 days",
            tips: json["tips"] as? [String] ?? ["Check soil before watering"]
        )
    }

    private func extractJSON(from text: String) -> String {
        // Try to find JSON content between ```json and ``` or just the raw JSON
        if let jsonStart = text.range(of: "```json")?.upperBound,
           let jsonEnd = text[jsonStart...].range(of: "```")?.lowerBound {
            return String(text[jsonStart..<jsonEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let jsonStart = text.range(of: "{"),
                  let jsonEnd = text.range(of: "}", options: .backwards) {
            return String(text[jsonStart.lowerBound...jsonEnd.upperBound])
        }
        return text
    }
}
