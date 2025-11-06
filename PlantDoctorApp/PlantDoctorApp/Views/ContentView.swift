//
//  ContentView.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PlantAnalysisViewModel()
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.3), Color.blue.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // App title
                    Text("🌱 Plant Doctor")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .padding(.top, 40)

                    Text("Diagnose your plant's health")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Image display
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(20)
                            .shadow(radius: 10)
                            .padding()
                    } else {
                        VStack {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.green.opacity(0.5))
                            Text("No plant selected")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 300)
                    }

                    // Analysis result
                    if viewModel.isAnalyzing {
                        ProgressView("Analyzing your plant...")
                            .padding()
                    } else if let result = viewModel.analysisResult {
                        AnalysisResultView(result: result)
                            .transition(.opacity)
                    }

                    Spacer()

                    // Action buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            sourceType = .camera
                            showCamera = true
                        }) {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 30))
                                Text("Camera")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }

                        Button(action: {
                            sourceType = .photoLibrary
                            showImagePicker = true
                        }) {
                            VStack {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 30))
                                Text("Gallery")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $viewModel.selectedImage, sourceType: sourceType)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $viewModel.selectedImage, sourceType: .camera)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
