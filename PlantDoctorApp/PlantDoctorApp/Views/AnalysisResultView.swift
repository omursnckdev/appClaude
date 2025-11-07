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
