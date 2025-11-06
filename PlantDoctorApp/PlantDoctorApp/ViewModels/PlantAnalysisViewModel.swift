//
//  PlantAnalysisViewModel.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import SwiftUI
import Combine

@MainActor
class PlantAnalysisViewModel: ObservableObject {
    @Published var selectedImage: UIImage? {
        didSet {
            if selectedImage != nil {
                analyzeImage()
            }
        }
    }

    @Published var analysisResult: PlantAnalysisResult?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    private let aiService: AIService
    private let firebaseService: FirebaseStorageService

    init() {
        self.aiService = AIService()
        self.firebaseService = FirebaseStorageService()
    }

    func analyzeImage() {
        guard let image = selectedImage else { return }

        isAnalyzing = true
        analysisResult = nil
        errorMessage = nil

        Task {
            do {
                // Upload image to Firebase Storage
                let imageUrl = try await firebaseService.uploadImage(image)
                print("Image uploaded to Firebase: \(imageUrl)")

                // Analyze with AI
                let result = try await aiService.analyzePlantImage(image)

                // Update UI
                self.analysisResult = result
                self.isAnalyzing = false
            } catch {
                self.errorMessage = "Analysis failed: \(error.localizedDescription)"
                self.isAnalyzing = false
            }
        }
    }
}
