# 🌱 Plant Doctor App

An iOS app that uses AI to diagnose plant diseases and health issues. Simply take a photo of your plant, and the app will analyze it to identify problems and provide treatment recommendations.

## Features

### Core Analysis
- 📸 **Camera Integration** - Take photos directly or choose from your photo library
- 🤖 **AI-Powered Analysis** - Uses Claude, OpenAI GPT-4 Vision, or Google Gemini for accurate plant disease detection
- 🌿 **Plant Identification** - Automatically identifies plant species with scientific names, care requirements, and detailed information
- 📊 **Detailed Results** - Get comprehensive diagnosis, identified problems, and treatment plans

### Advanced Features
- 📚 **History Tracking** - View and manage all your plant analyses with searchable history
- ⏰ **Care Reminders** - Set up watering, fertilizing, and maintenance reminders for your plants
- 👥 **Community Sharing** - Share your plant findings with other users and learn from the community
- 📱 **Offline Mode** - Local caching allows you to view past analyses without internet connection
- 🌍 **Multi-Language Support** - Available in 10+ languages (English, Spanish, French, German, Chinese, Japanese, Korean, Portuguese, Italian, Russian)
- 📄 **Export Reports** - Export individual analyses as PDF or entire history as CSV
- 🔥 **Firebase Backend** - Secure image storage and data management
- 🎨 **Beautiful SwiftUI Interface** - Modern, intuitive design with tab-based navigation

## Technology Stack

- **SwiftUI** - Native iOS user interface
- **Firebase** - Backend services (Storage, Authentication)
- **AI APIs** - Claude API (default), OpenAI GPT-4 Vision, or Google Gemini
- **iOS 16+** - Latest iOS features

## Prerequisites

- Xcode 15.0 or later
- iOS 16.0+ deployment target
- Active Apple Developer account (for device testing)
- Firebase account
- AI API key (Claude, OpenAI, or Gemini)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd appClaude
```

### 2. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Add an iOS app to your project:
   - Bundle ID: `com.yourcompany.PlantDoctorApp` (or your custom bundle ID)
   - Download the `GoogleService-Info.plist` file
4. Enable Firebase Storage:
   - In Firebase Console, go to Storage
   - Click "Get Started"
   - Choose production mode
   - Select a location for your storage bucket
5. Place the `GoogleService-Info.plist` file in:
   ```
   PlantDoctorApp/PlantDoctorApp/Resources/
   ```

### 3. API Key Configuration

1. Copy the example config file:
   ```bash
   cp PlantDoctorApp/PlantDoctorApp/Resources/Config.plist.example \
      PlantDoctorApp/PlantDoctorApp/Resources/Config.plist
   ```

2. Edit `Config.plist` and add your API keys:
   - **Claude API**: Get from [Anthropic Console](https://console.anthropic.com/)
   - **OpenAI API**: Get from [OpenAI Platform](https://platform.openai.com/)
   - **Gemini API**: Get from [Google AI Studio](https://makersuite.google.com/app/apikey)

### 4. Choose Your AI Service

The app currently uses Claude API by default. To switch to OpenAI or Gemini:

1. Open `PlantDoctorApp/ViewModels/PlantAnalysisViewModel.swift`
2. Change the AI service initialization:

```swift
// For Claude (default)
private let aiService: AIService

// For OpenAI
private let aiService: OpenAIService

// For Gemini
private let aiService: GeminiService
```

### 5. Open in Xcode

```bash
cd PlantDoctorApp
open PlantDoctorApp.xcodeproj
```

If the `.xcodeproj` file doesn't exist, create a new Xcode project:

1. Open Xcode
2. File → New → Project
3. Choose "iOS" → "App"
4. Product Name: `PlantDoctorApp`
5. Interface: SwiftUI
6. Language: Swift
7. Bundle Identifier: `com.yourcompany.PlantDoctorApp`
8. Move all files from `PlantDoctorApp/PlantDoctorApp/` into the new Xcode project

### 6. Add Firebase Dependencies

Using Swift Package Manager:

1. In Xcode, go to File → Add Package Dependencies
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select version 10.19.0 or later
4. Add these packages to your target:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage

### 7. Configure Project Settings

1. Select your project in Xcode
2. Under "Signing & Capabilities":
   - Select your development team
   - Ensure "Automatically manage signing" is checked
3. Update the bundle identifier if needed

### 8. Build and Run

1. Select a simulator or connected device
2. Press `Cmd + R` to build and run

## Project Structure

```
PlantDoctorApp/
├── PlantDoctorApp/
│   ├── PlantDoctorApp.swift          # App entry point
│   ├── Views/
│   │   ├── ContentView.swift         # Main view
│   │   ├── AnalysisResultView.swift  # Results display
│   │   └── ImagePicker.swift         # Camera/photo picker
│   ├── ViewModels/
│   │   └── PlantAnalysisViewModel.swift  # Business logic
│   ├── Models/
│   │   └── PlantAnalysisResult.swift    # Data models
│   ├── Services/
│   │   ├── AIService.swift              # Claude AI integration
│   │   ├── OpenAIService.swift          # OpenAI integration
│   │   ├── GeminiService.swift          # Gemini integration
│   │   └── FirebaseStorageService.swift # Firebase storage
│   ├── Resources/
│   │   ├── Config.plist                 # API keys
│   │   └── GoogleService-Info.plist     # Firebase config
│   └── Info.plist                       # App configuration
├── Package.swift                        # Dependencies
└── README.md
```

## Usage

### Analyzing Plants

1. **Launch the App** - Open Plant Doctor on your iOS device
2. **Choose Input Method**:
   - Tap "Camera" to take a new photo
   - Tap "Gallery" to select from your photo library
3. **Capture/Select Plant Image** - Make sure the plant and any visible issues are clearly visible
4. **Wait for Analysis** - The AI will process the image (usually takes 3-10 seconds)
5. **Review Results**:
   - Plant identification (species, care requirements)
   - Health status indicator
   - Detailed diagnosis
   - List of identified problems
   - Treatment recommendations
   - Confidence level

### Using History

1. Navigate to the **History** tab
2. View all your past plant analyses
3. Tap any record to see full details
4. Swipe left on a record to:
   - Export as PDF
   - Delete from history
5. Use the menu to:
   - Export all history as CSV
   - Clear entire history

### Setting Up Reminders

1. Navigate to the **Reminders** tab
2. Tap the **+** button to add a new reminder
3. Fill in:
   - Plant name
   - Reminder type (Watering, Fertilizing, Pruning, etc.)
   - Frequency in days
   - Optional notes
4. Mark reminders as completed by tapping the checkmark
5. View overdue reminders highlighted in red

### Sharing with Community

1. Navigate to the **Community** tab
2. Tap the share button to post an analysis
3. Select a plant from your history
4. Add a caption
5. Share with the community
6. Like and comment on others' posts
7. Pull down to refresh the feed

### Adjusting Settings

1. Navigate to the **Settings** tab
2. Change language preference
3. Select preferred AI provider (Claude/OpenAI/Gemini)
4. Toggle notifications
5. View and clear cache
6. Access about, privacy policy, and terms

## How It Works

1. **Image Capture** - User takes a photo using the device camera or selects from library
2. **Image Upload** - Photo is uploaded to Firebase Storage for backup and saved locally
3. **AI Analysis** - Image is sent to the selected AI service (Claude/OpenAI/Gemini)
4. **Plant Identification** - AI identifies the plant species, providing:
   - Common and scientific names
   - Plant family
   - Care level (Easy/Moderate/Difficult)
   - Watering and sunlight requirements
   - Brief description
5. **Health Analysis** - AI analyzes the plant for:
   - Leaf discoloration (yellowing, browning, spots)
   - Wilting or drooping
   - Pest infestations
   - Fungal infections
   - Nutrient deficiencies
   - Environmental stress
6. **Results Display** - Comprehensive identification and diagnosis shown to user
7. **Save to History** - Analysis is automatically saved for future reference
8. **Offline Caching** - Results are cached locally for offline viewing

## Troubleshooting

### Build Errors

- **"No such module 'Firebase'"**: Make sure Firebase SDK is added via Swift Package Manager
- **Missing Config.plist**: Copy and rename `Config.plist.example` to `Config.plist`
- **Missing GoogleService-Info.plist**: Download from Firebase Console

### Runtime Errors

- **"API key not found"**: Check that `Config.plist` exists and contains valid API keys
- **Camera not working**: Ensure you've added camera permission in `Info.plist`
- **Network errors**: Check your internet connection and API key validity

### Firebase Issues

- **Storage upload fails**: Verify Firebase Storage is enabled in your Firebase Console
- **Permission denied**: Check Firebase Security Rules allow uploads

## Security Notes

- **Never commit API keys** to version control - they are listed in `.gitignore`
- **Config.plist** and **GoogleService-Info.plist** are excluded from git
- Keep your API keys secure and rotate them if exposed
- Consider implementing rate limiting for production apps

## Completed Features ✅

- [x] History of analyzed plants
- [x] Plant identification (not just disease detection)
- [x] Care reminders and tracking
- [x] Community features (share findings)
- [x] Offline mode with cached data
- [x] Multiple language support
- [x] Export analysis reports (PDF & CSV)

## Future Enhancements

- [ ] Push notifications for care reminders
- [ ] Plant care journal with notes
- [ ] Advanced search and filters in history
- [ ] Social features (follow users, direct messaging)
- [ ] Plant care guides library
- [ ] Integration with plant care databases
- [ ] AR mode for plant visualization
- [ ] Voice commands for hands-free operation
- [ ] Plant health trends and analytics
- [ ] Integration with smart home devices

## API Cost Considerations

- **Claude API**: ~$0.01-0.02 per image analysis
- **OpenAI GPT-4 Vision**: ~$0.01-0.03 per image
- **Gemini**: Check current pricing at Google AI

For production use, consider implementing:
- User authentication
- Usage limits
- Caching for repeated queries
- Batch processing

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is available for educational purposes. Please ensure compliance with:
- Firebase Terms of Service
- OpenAI Usage Policies
- Anthropic Usage Policies
- Google AI Terms of Service

## Support

For issues and questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review Firebase and AI API documentation

## Credits

Built with:
- SwiftUI by Apple
- Firebase by Google
- Claude AI by Anthropic
- OpenAI GPT-4 Vision
- Google Gemini

---

Made with 🌱 for plant lovers everywhere
