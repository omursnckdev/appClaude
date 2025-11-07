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
    let plantIdentification: PlantIdentification?

    init(diagnosis: String, problems: [String], treatment: String, isHealthy: Bool, confidenceLevel: String, plantIdentification: PlantIdentification? = nil) {
        self.diagnosis = diagnosis
        self.problems = problems
        self.treatment = treatment
        self.isHealthy = isHealthy
        self.confidenceLevel = confidenceLevel
        self.plantIdentification = plantIdentification
    }
}
