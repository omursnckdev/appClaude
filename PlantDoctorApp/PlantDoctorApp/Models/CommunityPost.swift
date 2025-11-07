//
//  CommunityPost.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import Foundation

struct CommunityPost: Codable, Identifiable {
    let id: UUID
    let userId: String
    let userName: String
    let plantRecord: PlantRecord
    let caption: String
    let timestamp: Date
    var likes: Int
    var comments: [Comment]

    init(id: UUID = UUID(), userId: String, userName: String, plantRecord: PlantRecord, caption: String, timestamp: Date = Date(), likes: Int = 0, comments: [Comment] = []) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.plantRecord = plantRecord
        self.caption = caption
        self.timestamp = timestamp
        self.likes = likes
        self.comments = comments
    }

    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

struct Comment: Codable, Identifiable {
    let id: UUID
    let userId: String
    let userName: String
    let text: String
    let timestamp: Date

    init(id: UUID = UUID(), userId: String, userName: String, text: String, timestamp: Date = Date()) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.text = text
        self.timestamp = timestamp
    }
}
