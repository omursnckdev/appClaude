//
//  HistoryView.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var selectedRecord: PlantRecord?
    @State private var showingExportOptions = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.history.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(viewModel.history) { record in
                            HistoryRow(record: record)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedRecord = record
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deleteRecord(record)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        viewModel.exportRecord(record)
                                    } label: {
                                        Label("Export", systemImage: "square.and.arrow.up")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingExportOptions = true
                        }) {
                            Label("Export All", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive, action: {
                            viewModel.clearHistory()
                        }) {
                            Label("Clear History", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $selectedRecord) { record in
                RecordDetailView(record: record)
            }
            .confirmationDialog("Export Options", isPresented: $showingExportOptions) {
                Button("Export as CSV") {
                    viewModel.exportHistoryAsCSV()
                }
                Button("Export All as PDFs") {
                    viewModel.exportAllAsPDF()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

struct HistoryRow: View {
    let record: PlantRecord

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let image = PersistenceService.shared.loadImage(named: record.imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                if let identification = record.plantIdentification {
                    Text(identification.commonName)
                        .font(.headline)
                } else {
                    Text("Unknown Plant")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                Text(record.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Image(systemName: record.analysisResult.isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(record.analysisResult.isHealthy ? .green : .orange)
                        .font(.caption)

                    Text(record.analysisResult.isHealthy ? "Healthy" : "Issues")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No History Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Analyzed plants will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct RecordDetailView: View {
    let record: PlantRecord
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image
                    if let image = PersistenceService.shared.loadImage(named: record.imageName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }

                    // Plant Identification
                    if let identification = record.plantIdentification {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Plant Identification")
                                .font(.title2)
                                .fontWeight(.bold)

                            InfoRow(label: "Common Name", value: identification.commonName)
                            InfoRow(label: "Scientific Name", value: identification.scientificName)
                            InfoRow(label: "Family", value: identification.family)
                            InfoRow(label: "Care Level", value: identification.careLevel)

                            if !identification.description.isEmpty {
                                Text(identification.description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 5)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }

                    // Analysis Result
                    AnalysisResultView(result: record.analysisResult)
                }
                .padding()
            }
            .navigationTitle("Analysis Details")
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

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var history: [PlantRecord] = []

    init() {
        loadHistory()
    }

    func loadHistory() {
        history = PersistenceService.shared.getHistory()
    }

    func deleteRecord(_ record: PlantRecord) {
        PersistenceService.shared.deleteRecord(record)
        loadHistory()
    }

    func clearHistory() {
        PersistenceService.shared.clearHistory()
        loadHistory()
    }

    func exportRecord(_ record: PlantRecord) {
        let image = PersistenceService.shared.loadImage(named: record.imageName)
        if let pdfURL = ExportService.shared.exportToPDF(record: record, image: image) {
            shareFile(url: pdfURL)
        }
    }

    func exportHistoryAsCSV() {
        if let csvURL = ExportService.shared.exportHistoryToCSV(records: history) {
            shareFile(url: csvURL)
        }
    }

    func exportAllAsPDF() {
        // Export each record as PDF
        for record in history {
            let image = PersistenceService.shared.loadImage(named: record.imageName)
            if let pdfURL = ExportService.shared.exportToPDF(record: record, image: image) {
                shareFile(url: pdfURL)
            }
        }
    }

    private func shareFile(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
