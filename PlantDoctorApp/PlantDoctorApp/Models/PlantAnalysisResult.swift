//
//  PlantAnalysisResult.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import Foundation

struct PlantAnalysisResult: Codable {
    let diagnosis: String
    let problems: [String]
    let treatment: String
    let isHealthy: Bool
    let confidenceLevel: String

    init(diagnosis: String, problems: [String], treatment: String, isHealthy: Bool, confidenceLevel: String) {
        self.diagnosis = diagnosis
        self.problems = problems
        self.treatment = treatment
        self.isHealthy = isHealthy
        self.confidenceLevel = confidenceLevel
    }
}
