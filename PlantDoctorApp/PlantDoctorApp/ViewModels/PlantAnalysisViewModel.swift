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
    @Published var offlineMode = false

    private let aiService: AIService
    private let firebaseService: FirebaseStorageService
    private let persistenceService = PersistenceService.shared

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
                let imageName = UUID().uuidString + ".jpg"
                let language = LocalizationService.shared.getLanguage()

                // Try to upload image to Firebase Storage (skip if offline)
                var imageUrl: String?
                do {
                    imageUrl = try await firebaseService.uploadImage(image)
                    print("Image uploaded to Firebase: \(imageUrl)")
                } catch {
                    print("Firebase upload failed (possibly offline): \(error)")
                    offlineMode = true
                }

                // Save image locally
                _ = persistenceService.saveImage(image, withName: imageName)

                // Check cache first
                let cacheKey = imageName
                if let cachedResult = persistenceService.getCachedResult(for: cacheKey) {
                    print("Using cached result")
                    self.analysisResult = cachedResult
                    self.isAnalyzing = false
                    return
                }

                // Analyze with AI
                let result = try await aiService.analyzePlantImage(image, language: language)

                // Cache the result
                persistenceService.cacheAnalysisResult(imageId: cacheKey, result: result)

                // Save to history
                let record = PlantRecord(
                    imageUrl: imageUrl,
                    imageName: imageName,
                    analysisResult: result,
                    plantIdentification: result.plantIdentification,
                    plantName: result.plantIdentification?.commonName
                )
                persistenceService.saveRecord(record)

                // PlantDoctor 2.0 - Generate AI Calendar schedule for premium users
                if await PremiumService.shared.hasAccess(to: .aiCalendar) {
                    let aiSchedule = AICalendarService.shared.generateSchedule(
                        from: result,
                        plantRecord: record
                    )
                    AICalendarService.shared.saveSchedule(aiSchedule)
                    print("✅ AI Calendar schedule generated for \(record.plantName ?? "plant")")
                }

                // Update UI
                self.analysisResult = result
                self.isAnalyzing = false
                self.offlineMode = false
            } catch {
                // Check if we have offline mode available
                if self.offlineMode {
                    self.errorMessage = "Offline mode: Unable to analyze. Please connect to the internet."
                } else {
                    self.errorMessage = "Analysis failed: \(error.localizedDescription)"
                }
                self.isAnalyzing = false
            }
        }
    }
}
