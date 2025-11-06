//
//  GeminiService.swift
//  PlantDoctorApp
//
//  Alternative AI Service using Google Gemini Vision
//

import Foundation
import UIKit

class GeminiService {
    private let apiKey: String
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent"

    init() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["GEMINI_API_KEY"] as? String else {
            self.apiKey = ""
            print("Warning: Gemini API key not found in Config.plist")
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

        guard var urlComponents = URLComponents(string: endpoint) else {
            throw AIServiceError.networkError
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        guard let url = urlComponents.url else {
            throw AIServiceError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
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
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
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

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw AIServiceError.invalidResponse
        }

        // Parse the JSON response
        let jsonText = extractJSON(from: text)
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
