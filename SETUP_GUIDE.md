# Quick Setup Guide for Plant Doctor App

## Step-by-Step Setup (5 minutes)

### Step 1: Create Xcode Project

Since Xcode projects can't be easily created from command line, follow these steps:

1. **Open Xcode**
2. **File → New → Project**
3. Choose **iOS → App**
4. Fill in:
   - Product Name: `PlantDoctorApp`
   - Team: Select your team
   - Organization Identifier: `com.yourcompany` (or your domain)
   - Bundle Identifier: `com.yourcompany.PlantDoctorApp`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - Include Tests: ✓ (optional)

5. **Save** the project in the `PlantDoctorApp` directory that already exists

### Step 2: Replace Template Files

Xcode will create some default files. Replace them:

1. Delete the default `ContentView.swift` and `PlantDoctorApp.swift`
2. The files in this repository are already organized properly
3. In Xcode, **File → Add Files to "PlantDoctorApp"**
4. Add all the folders:
   - `Views/`
   - `ViewModels/`
   - `Models/`
   - `Services/`
   - `Resources/`

### Step 3: Add Firebase SDK

**Option A: Swift Package Manager (Recommended)**

1. In Xcode: **File → Add Package Dependencies**
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Version: 10.19.0 or later
4. Select packages:
   - ✓ FirebaseAuth
   - ✓ FirebaseFirestore
   - ✓ FirebaseStorage
5. Click **Add Package**

**Option B: CocoaPods**

```bash
cd PlantDoctorApp
pod install
# Then open PlantDoctorApp.xcworkspace instead of .xcodeproj
```

### Step 4: Configure Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project or select existing
3. Add iOS app:
   - Enter your Bundle ID
   - Download `GoogleService-Info.plist`
4. **Drag** `GoogleService-Info.plist` into Xcode project under `Resources/`
5. Enable **Storage** in Firebase Console:
   - Navigate to Storage → Get Started
   - Choose production mode

### Step 5: Add API Keys

1. Copy the config template:
   ```bash
   cd PlantDoctorApp/Resources
   cp Config.plist.example Config.plist
   ```

2. Edit `Config.plist` and add your key:

   **For Claude (Recommended):**
   - Get key from: https://console.anthropic.com/
   - Add to `CLAUDE_API_KEY` field

   **For OpenAI:**
   - Get key from: https://platform.openai.com/
   - Add to `OPENAI_API_KEY` field
   - In `ViewModels/PlantAnalysisViewModel.swift`, change:
     ```swift
     private let aiService = OpenAIService()
     ```

   **For Gemini:**
   - Get key from: https://makersuite.google.com/app/apikey
   - Add to `GEMINI_API_KEY` field
   - In `ViewModels/PlantAnalysisViewModel.swift`, change:
     ```swift
     private let aiService = GeminiService()
     ```

3. **Drag** `Config.plist` into Xcode under `Resources/`

### Step 6: Update Info.plist

The `Info.plist` is already configured, but verify it includes:

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos of your plants.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to analyze plant images.</string>
```

### Step 7: Build and Run

1. Select a simulator (iPhone 14 Pro or later recommended)
2. Press **⌘ + R** to build and run
3. Grant camera and photo permissions when prompted

## Verification Checklist

- [ ] Xcode project opens without errors
- [ ] All Swift files are visible in Project Navigator
- [ ] Firebase SDK added successfully
- [ ] `GoogleService-Info.plist` in project
- [ ] `Config.plist` with valid API key in project
- [ ] Project builds without errors
- [ ] App launches in simulator
- [ ] Can access camera/photo library
- [ ] Image analysis works

## Common Issues

### "No such module 'Firebase'"
- Make sure you added Firebase via SPM or CocoaPods
- Clean build folder: **Product → Clean Build Folder** (⇧⌘K)
- Rebuild: **Product → Build** (⌘B)

### "Config.plist not found"
- Ensure you copied and renamed `Config.plist.example` to `Config.plist`
- Drag `Config.plist` into Xcode project
- Verify it's in the "Copy Bundle Resources" build phase

### "GoogleService-Info.plist not found"
- Download from Firebase Console
- Drag into Xcode (ensure "Copy items if needed" is checked)
- Verify it's in the "Copy Bundle Resources" build phase

### Camera not working in Simulator
- Camera doesn't work in Simulator - use "Gallery" button instead
- Or run on a physical device for full camera functionality

### API Rate Limits
- Claude: Check your plan limits
- OpenAI: Verify you have credits
- Gemini: Check quota in Google Cloud Console

## Next Steps

Once the app is running:

1. **Test with sample plant images**
2. **Customize the UI** in `Views/ContentView.swift`
3. **Adjust AI prompts** in `Services/AIService.swift`
4. **Add features** like history, plant library, etc.

## Need Help?

- Check the main README.md for detailed documentation
- Review Firebase documentation: https://firebase.google.com/docs
- Check AI API documentation:
  - Claude: https://docs.anthropic.com/
  - OpenAI: https://platform.openai.com/docs
  - Gemini: https://ai.google.dev/docs

---

Happy coding! 🌱
