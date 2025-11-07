//
//  CommunityService.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import Foundation
import FirebaseFirestore

class CommunityService {
    static let shared = CommunityService()

    private let db = Firestore.firestore()
    private let postsCollection = "community_posts"

    private init() {}

    // MARK: - Post Management

    func sharePost(_ post: CommunityPost) async throws {
        let postData: [String: Any] = [
            "id": post.id.uuidString,
            "userId": post.userId,
            "userName": post.userName,
            "caption": post.caption,
            "timestamp": Timestamp(date: post.timestamp),
            "likes": post.likes,
            "plantRecord": try encodeToDict(post.plantRecord)
        ]

        try await db.collection(postsCollection).document(post.id.uuidString).setData(postData)
    }

    func fetchPosts(limit: Int = 20) async throws -> [CommunityPost] {
        let snapshot = try await db.collection(postsCollection)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()

        var posts: [CommunityPost] = []

        for document in snapshot.documents {
            if let post = try? parseCommunityPost(from: document.data()) {
                posts.append(post)
            }
        }

        return posts
    }

    func likePost(_ postId: UUID) async throws {
        let postRef = db.collection(postsCollection).document(postId.uuidString)

        try await db.runTransaction { transaction, errorPointer in
            let postDocument: DocumentSnapshot
            do {
                try postDocument = transaction.getDocument(postRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let currentLikes = postDocument.data()?["likes"] as? Int else {
                return nil
            }

            transaction.updateData(["likes": currentLikes + 1], forDocument: postRef)
            return nil
        }
    }

    func addComment(_ comment: Comment, to postId: UUID) async throws {
        let commentData: [String: Any] = [
            "id": comment.id.uuidString,
            "userId": comment.userId,
            "userName": comment.userName,
            "text": comment.text,
            "timestamp": Timestamp(date: comment.timestamp)
        ]

        try await db.collection(postsCollection)
            .document(postId.uuidString)
            .collection("comments")
            .document(comment.id.uuidString)
            .setData(commentData)
    }

    func fetchComments(for postId: UUID) async throws -> [Comment] {
        let snapshot = try await db.collection(postsCollection)
            .document(postId.uuidString)
            .collection("comments")
            .order(by: "timestamp", descending: false)
            .getDocuments()

        var comments: [Comment] = []

        for document in snapshot.documents {
            let data = document.data()
            if let id = UUID(uuidString: data["id"] as? String ?? ""),
               let userId = data["userId"] as? String,
               let userName = data["userName"] as? String,
               let text = data["text"] as? String,
               let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() {
                comments.append(Comment(id: id, userId: userId, userName: userName, text: text, timestamp: timestamp))
            }
        }

        return comments
    }

    // MARK: - Helper Methods

    private func encodeToDict<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return dict ?? [:]
    }

    private func parseCommunityPost(from data: [String: Any]) throws -> CommunityPost {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let userName = data["userName"] as? String,
              let caption = data["caption"] as? String,
              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
              let likes = data["likes"] as? Int,
              let plantRecordData = data["plantRecord"] as? [String: Any] else {
            throw NSError(domain: "CommunityService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid post data"])
        }

        let plantRecordJSON = try JSONSerialization.data(withJSONObject: plantRecordData)
        let plantRecord = try JSONDecoder().decode(PlantRecord.self, from: plantRecordJSON)

        return CommunityPost(
            id: id,
            userId: userId,
            userName: userName,
            plantRecord: plantRecord,
            caption: caption,
            timestamp: timestamp,
            likes: likes,
            comments: []
        )
    }
}
