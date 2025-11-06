//
//  FirebaseStorageService.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import Foundation
import UIKit
import FirebaseStorage

class FirebaseStorageService {
    private let storage = Storage.storage()

    func uploadImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "FirebaseStorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }

        let storageRef = storage.reference()
        let imageRef = storageRef.child("plant_images/\(UUID().uuidString).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await imageRef.downloadURL()

        return downloadURL.absoluteString
    }
}
