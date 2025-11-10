//
//  AnalysisResultView.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import SwiftUI

struct AnalysisResultView: View {
    let result: PlantAnalysisResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                // Plant Identification
                if let identification = result.plantIdentification {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plant Identification")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(identification.commonName)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text(identification.scientificName)
                                    .font(.subheadline)
                                    .italic()
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }

                        if !identification.description.isEmpty {
                            Text(identification.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: 20) {
                            HStack(spacing: 4) {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.blue)
                                Text(identification.wateringNeeds)
                                    .font(.caption)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "sun.max.fill")
                                    .foregroundColor(.orange)
                                Text(identification.sunlightNeeds)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.bottom, 10)

                    Divider()
                }

                // Health status
                HStack {
                    Image(systemName: result.isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(result.isHealthy ? .green : .orange)

                    Text(result.isHealthy ? "Plant looks healthy!" : "Issues detected")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 5)

                // Diagnosis
                if !result.diagnosis.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Diagnosis")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(result.diagnosis)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Problems found
                if !result.problems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Problems Found")
                            .font(.headline)
                            .foregroundColor(.primary)

                        ForEach(result.problems, id: \.self) { problem in
                            HStack(alignment: .top) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.red)
                                    .padding(.top, 6)
                                Text(problem)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Treatment recommendations
                if !result.treatment.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Treatment Recommendations")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(result.treatment)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // PlantDoctor 2.0 - Environmental Conditions
                if let environmental = result.environmentalConditions {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("🌿 Environmental Analysis")
                            .font(.headline)
                            .foregroundColor(.primary)

                        // Humidity
                        EnvironmentalCard(
                            icon: "humidity.fill",
                            iconColor: .blue,
                            title: "Humidity",
                            current: environmental.humidity.current,
                            ideal: environmental.humidity.ideal,
                            recommendation: environmental.humidity.adjustment
                        )

                        // Light
                        EnvironmentalCard(
                            icon: "sun.max.fill",
                            iconColor: .orange,
                            title: "Light",
                            current: environmental.light.current,
                            ideal: "\(environmental.light.ideal) (\(environmental.light.hoursPerDay))",
                            recommendation: environmental.light.adjustment
                        )

                        // Temperature
                        EnvironmentalCard(
                            icon: "thermometer.medium",
                            iconColor: .red,
                            title: "Temperature",
                            current: environmental.temperature.current,
                            ideal: environmental.temperature.ideal,
                            recommendation: environmental.temperature.warnings.first ?? ""
                        )

                        // Soil Moisture
                        EnvironmentalCard(
                            icon: "drop.fill",
                            iconColor: .cyan,
                            title: "Soil Moisture",
                            current: environmental.soilMoisture.current,
                            ideal: "\(environmental.soilMoisture.ideal) - \(environmental.soilMoisture.wateringFrequency)",
                            recommendation: environmental.soilMoisture.tips.first ?? ""
                        )
                    }
                }

                // Recovery time estimate
                if let recoveryTime = result.estimatedRecoveryTime {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.green)
                        Text("Recovery Time:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(recoveryTime)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 5)
                }

                // Confidence level
                HStack {
                    Text("Confidence:")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(result.confidenceLevel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 5)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 5)
            .padding()
        }
        .frame(maxHeight: 400)
    }
}

// MARK: - Environmental Card Component (PlantDoctor 2.0)
struct EnvironmentalCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let current: String
    let ideal: String
    let recommendation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            HStack {
                Text("Current:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(current)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
            }

            HStack {
                Text("Ideal:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(ideal)
                    .font(.caption)
            }

            if !recommendation.isEmpty {
                Text("💡 \(recommendation)")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .italic()
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    private var statusColor: Color {
        let currentLower = current.lowercased()
        if currentLower.contains("good") || currentLower.contains("adequate") || currentLower.contains("healthy") {
            return .green
        } else if currentLower.contains("low") || currentLower.contains("insufficient") || currentLower.contains("high") || currentLower.contains("excessive") {
            return .orange
        } else if currentLower.contains("dry") || currentLower.contains("overwater") {
            return .red
        }
        return .primary
    }
}

struct AnalysisResultView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisResultView(result: PlantAnalysisResult(
            diagnosis: "Leaf spot disease detected",
            problems: ["Brown spots on leaves", "Yellowing around edges"],
            treatment: "Remove affected leaves and apply fungicide",
            isHealthy: false,
            confidenceLevel: "High"
        ))
    }
}
