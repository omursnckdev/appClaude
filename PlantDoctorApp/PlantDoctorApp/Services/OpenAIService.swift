//
//  OpenAIService.swift
//  PlantDoctorApp
//
//  Alternative AI Service using OpenAI GPT-4 Vision
//

import Foundation
import UIKit

class OpenAIService {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"

    init() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["OPENAI_API_KEY"] as? String else {
            self.apiKey = ""
            print("Warning: OpenAI API key not found in Config.plist")
            return
        }
        self.apiKey = key
    }

    func analyzePlantImage(_ image: UIImage) async throws -> PlantAnalysisResult {
        guard !apiKey.isEmpty else {
            throw AIServiceError.apiKeyMissing
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AIServiceError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": """
                            You are a plant disease expert. Analyze this plant image and provide a diagnosis.

                            Please respond in the following JSON format:
                            {
                                "isHealthy": true/false,
                                "diagnosis": "Brief diagnosis of the plant's condition",
                                "problems": ["list", "of", "specific", "issues"],
                                "treatment": "Detailed treatment recommendations",
                                "confidenceLevel": "High/Medium/Low"
                            }

                            Look for signs of disease, pests, nutrient deficiencies, and environmental stress.
                            """
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 1000
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.networkError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }

        // Parse the JSON response
        let jsonText = extractJSON(from: content)
        guard let jsonData = jsonText.data(using: .utf8),
              let analysisJson = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw AIServiceError.invalidResponse
        }

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
            confidenceLevel: confidenceLevel
        )
    }

    private func extractJSON(from text: String) -> String {
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
