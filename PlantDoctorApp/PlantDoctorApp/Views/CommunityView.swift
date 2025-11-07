//
//  CommunityView.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @State private var showingShareSheet = false
    @State private var selectedRecord: PlantRecord?

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading community posts...")
                } else if viewModel.posts.isEmpty {
                    EmptyCommunityView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(viewModel.posts) { post in
                                CommunityPostCard(post: post, viewModel: viewModel)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadPosts()
                    }
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                SharePostView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadPosts()
            }
        }
    }
}

struct CommunityPostCard: View {
    let post: CommunityPost
    @ObservedObject var viewModel: CommunityViewModel
    @State private var showingComments = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(post.userName.prefix(1).uppercased())
                            .font(.headline)
                    )

                VStack(alignment: .leading) {
                    Text(post.userName)
                        .font(.headline)
                    Text(post.formattedTimestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Image
            if let image = PersistenceService.shared.loadImage(named: post.plantRecord.imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
            }

            // Plant info
            if let identification = post.plantRecord.plantIdentification {
                Text(identification.commonName)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            // Caption
            Text(post.caption)
                .font(.body)

            // Diagnosis
            HStack {
                Image(systemName: post.plantRecord.analysisResult.isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(post.plantRecord.analysisResult.isHealthy ? .green : .orange)

                Text(post.plantRecord.analysisResult.diagnosis)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Actions
            HStack(spacing: 20) {
                Button(action: {
                    Task {
                        await viewModel.likePost(post.id)
                    }
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("\(post.likes)")
                    }
                    .foregroundColor(.red)
                }

                Button(action: {
                    showingComments = true
                }) {
                    HStack {
                        Image(systemName: "message")
                        Text("\(post.comments.count)")
                    }
                    .foregroundColor(.blue)
                }

                Spacer()
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
        .sheet(isPresented: $showingComments) {
            CommentsView(post: post, viewModel: viewModel)
        }
    }
}

struct EmptyCommunityView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Community Posts")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Be the first to share your plant analysis!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct SharePostView: View {
    @ObservedObject var viewModel: CommunityViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedRecord: PlantRecord?
    @State private var caption = ""
    @State private var userName = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Your Information")) {
                    TextField("Your Name", text: $userName)
                }

                Section(header: Text("Select Plant Analysis")) {
                    let history = PersistenceService.shared.getHistory()
                    ForEach(history.prefix(10)) { record in
                        Button(action: {
                            selectedRecord = record
                        }) {
                            HStack {
                                if let image = PersistenceService.shared.loadImage(named: record.imageName) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }

                                VStack(alignment: .leading) {
                                    Text(record.plantIdentification?.commonName ?? "Unknown")
                                        .font(.headline)
                                    Text(record.formattedDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedRecord?.id == record.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Caption")) {
                    TextEditor(text: $caption)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Share to Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        if let record = selectedRecord {
                            Task {
                                await viewModel.sharePost(record: record, caption: caption, userName: userName)
                                dismiss()
                            }
                        }
                    }
                    .disabled(selectedRecord == nil || userName.isEmpty)
                }
            }
        }
    }
}

struct CommentsView: View {
    let post: CommunityPost
    @ObservedObject var viewModel: CommunityViewModel
    @Environment(\.dismiss) var dismiss

    @State private var commentText = ""
    @State private var userName = ""

    var body: some View {
        NavigationView {
            VStack {
                List(post.comments) { comment in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(comment.userName)
                            .font(.headline)
                        Text(comment.text)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }

                HStack {
                    TextField("Your name", text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)

                    TextField("Add a comment...", text: $commentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: {
                        Task {
                            await viewModel.addComment(to: post.id, userName: userName, text: commentText)
                            commentText = ""
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(commentText.isEmpty || userName.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

@MainActor
class CommunityViewModel: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var isLoading = false

    func loadPosts() async {
        isLoading = true
        do {
            posts = try await CommunityService.shared.fetchPosts()
        } catch {
            print("Error loading posts: \(error)")
        }
        isLoading = false
    }

    func sharePost(record: PlantRecord, caption: String, userName: String) async {
        let post = CommunityPost(
            userId: UUID().uuidString,
            userName: userName,
            plantRecord: record,
            caption: caption
        )

        do {
            try await CommunityService.shared.sharePost(post)
            await loadPosts()
        } catch {
            print("Error sharing post: \(error)")
        }
    }

    func likePost(_ postId: UUID) async {
        do {
            try await CommunityService.shared.likePost(postId)
            await loadPosts()
        } catch {
            print("Error liking post: \(error)")
        }
    }

    func addComment(to postId: UUID, userName: String, text: String) async {
        let comment = Comment(
            userId: UUID().uuidString,
            userName: userName,
            text: text
        )

        do {
            try await CommunityService.shared.addComment(comment, to: postId)
            await loadPosts()
        } catch {
            print("Error adding comment: \(error)")
        }
    }
}
