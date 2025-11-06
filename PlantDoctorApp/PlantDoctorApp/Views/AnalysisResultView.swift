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
