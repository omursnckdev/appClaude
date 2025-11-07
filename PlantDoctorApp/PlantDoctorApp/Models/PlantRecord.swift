//
//  PlantRecord.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import Foundation
import UIKit

struct PlantRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let imageUrl: String?
    let imageName: String
    let analysisResult: PlantAnalysisResult
    let plantIdentification: PlantIdentification?
    let plantName: String?

    init(id: UUID = UUID(), date: Date = Date(), imageUrl: String? = nil, imageName: String, analysisResult: PlantAnalysisResult, plantIdentification: PlantIdentification? = nil, plantName: String? = nil) {
        self.id = id
        self.date = date
        self.imageUrl = imageUrl
        self.imageName = imageName
        self.analysisResult = analysisResult
        self.plantIdentification = plantIdentification
        self.plantName = plantName
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PlantIdentification: Codable {
    let species: String
    let commonName: String
    let scientificName: String
    let family: String
    let description: String
    let careLevel: String
    let wateringNeeds: String
    let sunlightNeeds: String
    let confidenceLevel: String
}
