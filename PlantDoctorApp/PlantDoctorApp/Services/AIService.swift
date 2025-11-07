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
                            You are a plant expert. Analyze this plant image and provide both identification and health diagnosis.

                            Please respond in the following JSON format:
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
                                "diagnosis": "Brief diagnosis of the plant's condition",
                                "problems": ["list", "of", "specific", "issues"],
                                "treatment": "Detailed treatment recommendations",
                                "confidenceLevel": "High/Medium/Low"
                            }

                            First, identify the plant species. Then look for health issues:
                            - Leaf discoloration (yellowing, browning, spots)
                            - Wilting or drooping
                            - Pests or insects
                            - Fungal infections
                            - Nutrient deficiencies
                            - Root problems
                            - Environmental stress

                            Respond in \(language.displayName) language.
                            Be specific and provide actionable treatment advice.
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

        // Parse the analysis result
        let isHealthy = analysisJson["isHealthy"] as? Bool ?? false
        let diagnosis = analysisJson["diagnosis"] as? String ?? "Unable to determine"
        let problems = analysisJson["problems"] as? [String] ?? []
        let treatment = analysisJson["treatment"] as? String ?? "Consult a plant specialist"
        let confidenceLevel = analysisJson["confidenceLevel"] as? String ?? "Medium"

        return PlantAnalysisResult(
            diagnosis: diagnosis,
            problems: problems,
            treatment: treatment,
            isHealthy: isHealthy,
            confidenceLevel: confidenceLevel,
            plantIdentification: plantIdentification
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
